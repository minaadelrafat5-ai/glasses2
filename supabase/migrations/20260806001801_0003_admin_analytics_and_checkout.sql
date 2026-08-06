/*
# Vuera — Admin Analytics & Secure Order Creation

## Purpose
1. Read-only analytics helpers for the admin dashboard (sales totals,
   best sellers, low stock, revenue chart, recent orders, customer
   activity, role update).
2. A SECURITY DEFINER function `create_order` that lets an authenticated
   customer place an order. Prices are recomputed server-side from the
   product_variants table — the client-supplied cart is treated as input,
   never as fact. Stock is validated and decremented atomically inside the
   transaction. No real payment gateway yet: the order is created in
   'pending' status and a `payment_intent_id` placeholder is accepted for
   future Stripe integration.

## New Objects
- admin_dashboard_summary(), admin_best_sellers(limit), admin_low_stock(threshold),
  admin_revenue_by_day(days), admin_recent_orders(limit), admin_customer_activity(userId),
  admin_update_profile_role(userId, role)
- create_order(p_items jsonb, p_shipping_address jsonb, p_customer_email text,
  p_payment_intent_id text) — returns the new order id. Authorizes the caller
  via auth.uid(), recomputes subtotal from live variant prices, computes
  shipping (free) and tax (8.5% placeholder), validates stock + quantity
  bounds, decrements stock, inserts order + order_items, clears the caller's
  cart_items.

## Security
- All admin_* functions are SECURITY DEFINER, check public.is_staff(), and
  raise 42501 if not staff.
- create_order is SECURITY DEFINER (it writes order_items which have no
  INSERT policy for customers). It derives user_id from auth.uid() — never
  from a parameter. EXECUTE granted to authenticated only.

## Notes
1. Money values remain integer cents.
2. Shipping is free ($0) for now; tax is a flat 8.5% placeholder computed
   server-side. Both are easy to swap for real rules later.
3. Quantity is bounded 1..100 per line. Each variant must exist, be active,
   and have stock >= requested quantity.
4. The function clears the caller's cart on success so the UI stays in sync.
5. A payment_intent_id text column is added to orders for future Stripe
   integration (nullable, no policy impact).
*/

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS payment_intent_id text;

-- ============================================================
-- Admin analytics
-- ============================================================

CREATE OR REPLACE FUNCTION public.admin_dashboard_summary()
RETURNS TABLE (
  total_sales_cents bigint, total_orders bigint, total_customers bigint,
  total_products bigint, low_stock_variants bigint, pending_orders bigint
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT
    COALESCE(SUM(o.total_cents), 0)::bigint AS total_sales_cents,
    COUNT(DISTINCT o.id)::bigint AS total_orders,
    (SELECT COUNT(*)::bigint FROM public.profiles WHERE role = 'customer') AS total_customers,
    (SELECT COUNT(*)::bigint FROM public.products WHERE status = 'active') AS total_products,
    (SELECT COUNT(*)::bigint FROM public.product_variants WHERE stock <= 10) AS low_stock_variants,
    (SELECT COUNT(*)::bigint FROM public.orders WHERE status = 'pending') AS pending_orders
  FROM public.orders o
  WHERE o.status IN ('paid', 'fulfilled', 'shipped', 'delivered');
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_best_sellers(p_limit int DEFAULT 5)
RETURNS TABLE (product_id uuid, product_name text, units_sold bigint, revenue_cents bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT oi.product_id, oi.product_name,
    SUM(oi.quantity)::bigint AS units_sold,
    SUM(oi.unit_price_cents * oi.quantity)::bigint AS revenue_cents
  FROM public.order_items oi
  JOIN public.orders o ON o.id = oi.order_id
  WHERE o.status IN ('paid', 'fulfilled', 'shipped', 'delivered')
  GROUP BY oi.product_id, oi.product_name
  ORDER BY revenue_cents DESC
  LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_low_stock(p_threshold int DEFAULT 10)
RETURNS TABLE (variant_id uuid, product_id uuid, product_name text, variant_name text, sku text, stock int, price_cents int)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT pv.id, p.id, p.name, pv.name, pv.sku, pv.stock, pv.price_cents
  FROM public.product_variants pv
  JOIN public.products p ON p.id = pv.product_id
  WHERE pv.stock <= p_threshold
  ORDER BY pv.stock ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_revenue_by_day(p_days int DEFAULT 30)
RETURNS TABLE (day date, revenue_cents bigint, order_count bigint)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT DATE(o.created_at) AS day,
    SUM(o.total_cents)::bigint AS revenue_cents,
    COUNT(DISTINCT o.id)::bigint AS order_count
  FROM public.orders o
  WHERE o.status IN ('paid', 'fulfilled', 'shipped', 'delivered')
    AND o.created_at >= now() - (p_days || ' days')::interval
  GROUP BY DATE(o.created_at)
  ORDER BY day ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_recent_orders(p_limit int DEFAULT 10)
RETURNS TABLE (order_id uuid, customer_email text, status text, total_cents int, item_count bigint, created_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT o.id, pr.email, o.status, o.total_cents,
    (SELECT COUNT(*)::bigint FROM public.order_items oi WHERE oi.order_id = o.id),
    o.created_at
  FROM public.orders o
  LEFT JOIN public.profiles pr ON pr.id = o.user_id
  ORDER BY o.created_at DESC
  LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_customer_activity(p_user_id uuid)
RETURNS TABLE (order_count bigint, total_spent_cents bigint, review_count bigint, wishlist_count bigint, has_preferences boolean)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::bigint FROM public.orders WHERE user_id = p_user_id),
    (SELECT COALESCE(SUM(total_cents), 0)::bigint FROM public.orders WHERE user_id = p_user_id AND status IN ('paid','fulfilled','shipped','delivered')),
    (SELECT COUNT(*)::bigint FROM public.reviews WHERE user_id = p_user_id),
    (SELECT COUNT(*)::bigint FROM public.wishlist_items WHERE user_id = p_user_id),
    (SELECT EXISTS(SELECT 1 FROM public.customer_preferences WHERE user_id = p_user_id));
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_update_profile_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;
  IF p_role NOT IN ('customer', 'admin', 'staff') THEN
    RAISE EXCEPTION 'Invalid role: %', p_role USING ERRCODE = '23514';
  END IF;
  UPDATE public.profiles SET role = p_role WHERE id = p_user_id;
END;
$$;

-- ============================================================
-- Secure order creation (customer-facing)
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_order(
  p_items jsonb,
  p_shipping_address jsonb,
  p_customer_email text DEFAULT NULL,
  p_payment_intent_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_order_id uuid;
  v_item jsonb;
  v_variant_id uuid;
  v_quantity int;
  v_unit_price int;
  v_product_name text;
  v_variant_name text;
  v_subtotal int := 0;
  v_shipping int := 0;
  v_tax int;
  v_total int;
  v_stock int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Sign in required to place an order' USING ERRCODE = '42501';
  END IF;

  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Cannot place an empty order' USING ERRCODE = '23514';
  END IF;
  IF jsonb_array_length(p_items) > 100 THEN
    RAISE EXCEPTION 'Too many items in order' USING ERRCODE = '23514';
  END IF;

  -- Insert the order header first (status pending).
  INSERT INTO public.orders (user_id, status, subtotal_cents, shipping_cents, tax_cents, total_cents, currency, shipping_address, customer_email, payment_intent_id)
  VALUES (v_user_id, 'pending', 0, 0, 0, 0, 'USD', p_shipping_address, p_customer_email, p_payment_intent_id)
  RETURNING id INTO v_order_id;

  -- Process each line: validate, recompute price from live data, decrement stock.
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_variant_id := (v_item->>'variant_id')::uuid;
    v_quantity := (v_item->>'quantity')::int;

    IF v_quantity IS NULL OR v_quantity < 1 OR v_quantity > 100 THEN
      RAISE EXCEPTION 'Invalid quantity for an item' USING ERRCODE = '23514';
    END IF;

    SELECT pv.price_cents, pv.stock, pv.name, p.name
      INTO v_unit_price, v_stock, v_variant_name, v_product_name
    FROM public.product_variants pv
    JOIN public.products p ON p.id = pv.product_id
    WHERE pv.id = v_variant_id AND p.status = 'active';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'One of the items is no longer available' USING ERRCODE = '23514';
    END IF;

    IF v_stock < v_quantity THEN
      RAISE EXCEPTION 'Not enough stock for %', v_variant_name USING ERRCODE = '23514';
    END IF;

    -- Atomic stock decrement with a guard.
    UPDATE public.product_variants
      SET stock = stock - v_quantity
      WHERE id = v_variant_id AND stock >= v_quantity;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Stock changed during checkout for %', v_variant_name USING ERRCODE = '23514';
    END IF;

    INSERT INTO public.order_items (order_id, product_id, variant_id, product_name, variant_name, unit_price_cents, quantity)
    VALUES (v_order_id, (v_item->>'product_id')::uuid, v_variant_id, v_product_name, v_variant_name, v_unit_price, v_quantity);

    v_subtotal := v_subtotal + (v_unit_price * v_quantity);
  END LOOP;

  -- Shipping is free for now; tax is a flat 8.5% placeholder (rounded).
  v_shipping := 0;
  v_tax := round(v_subtotal * 0.085)::int;
  v_total := v_subtotal + v_shipping + v_tax;

  UPDATE public.orders
    SET subtotal_cents = v_subtotal, shipping_cents = v_shipping, tax_cents = v_tax, total_cents = v_total
    WHERE id = v_order_id;

  -- Clear the caller's cart so the UI stays in sync.
  DELETE FROM public.cart_items WHERE user_id = v_user_id;

  RETURN v_order_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_order(jsonb, jsonb, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.create_order(jsonb, jsonb, text, text) TO authenticated;
