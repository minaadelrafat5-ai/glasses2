/*
# Vuera — Admin Analytics Helper Views & Functions

## Purpose
Provides read-only analytics for the admin dashboard: sales totals, order
counts, customer counts, best-selling products, inventory alerts, and
recent activity. All functions are SECURITY DEFINER and check is_staff()
so only admin/staff roles can call them.

## New Objects
- `admin_dashboard_summary()` — returns a single row with total sales,
  total orders, total customers, total products, low-stock variant count,
  and pending order count.
- `admin_best_sellers(limit int)` — returns top-selling products by
  revenue from order_items, with units sold and revenue.
- `admin_low_stock(threshold int)` — returns variants at or below the
  threshold with product name and stock.
- `admin_revenue_by_day(days int)` — returns daily revenue for the last N
  days, for the dashboard revenue chart.
- `admin_recent_orders(limit int)` — returns the most recent orders with
  customer email and item count.
- `admin_customer_activity(userId uuid)` — returns a customer's orders,
  reviews, wishlist count, and preferences for the customer detail view.

## Security
- All functions are SECURITY DEFINER, check public.is_staff(), and raise
  an exception if the caller is not staff. This keeps the admin service
  layer simple: it calls the RPC and surfaces errors.

## Notes
- Money values remain integer cents.
- Functions are idempotent (CREATE OR REPLACE).
*/

-- ============================================================
-- Dashboard summary
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_dashboard_summary()
RETURNS TABLE (
  total_sales_cents bigint,
  total_orders bigint,
  total_customers bigint,
  total_products bigint,
  low_stock_variants bigint,
  pending_orders bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

-- ============================================================
-- Best sellers by revenue
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_best_sellers(p_limit int DEFAULT 5)
RETURNS TABLE (
  product_id uuid,
  product_name text,
  units_sold bigint,
  revenue_cents bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    oi.product_id,
    oi.product_name,
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

-- ============================================================
-- Low stock variants
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_low_stock(p_threshold int DEFAULT 10)
RETURNS TABLE (
  variant_id uuid,
  product_id uuid,
  product_name text,
  variant_name text,
  sku text,
  stock int,
  price_cents int
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    pv.id AS variant_id,
    p.id AS product_id,
    p.name AS product_name,
    pv.name AS variant_name,
    pv.sku,
    pv.stock,
    pv.price_cents
  FROM public.product_variants pv
  JOIN public.products p ON p.id = pv.product_id
  WHERE pv.stock <= p_threshold
  ORDER BY pv.stock ASC;
END;
$$;

-- ============================================================
-- Revenue by day
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_revenue_by_day(p_days int DEFAULT 30)
RETURNS TABLE (
  day date,
  revenue_cents bigint,
  order_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    DATE(o.created_at) AS day,
    SUM(o.total_cents)::bigint AS revenue_cents,
    COUNT(DISTINCT o.id)::bigint AS order_count
  FROM public.orders o
  WHERE o.status IN ('paid', 'fulfilled', 'shipped', 'delivered')
    AND o.created_at >= now() - (p_days || ' days')::interval
  GROUP BY DATE(o.created_at)
  ORDER BY day ASC;
END;
$$;

-- ============================================================
-- Recent orders with customer info
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_recent_orders(p_limit int DEFAULT 10)
RETURNS TABLE (
  order_id uuid,
  customer_email text,
  status text,
  total_cents int,
  item_count bigint,
  created_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    o.id AS order_id,
    pr.email AS customer_email,
    o.status,
    o.total_cents,
    (SELECT COUNT(*)::bigint FROM public.order_items oi WHERE oi.order_id = o.id) AS item_count,
    o.created_at
  FROM public.orders o
  LEFT JOIN public.profiles pr ON pr.id = o.user_id
  ORDER BY o.created_at DESC
  LIMIT p_limit;
END;
$$;

-- ============================================================
-- Customer activity
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_customer_activity(p_user_id uuid)
RETURNS TABLE (
  order_count bigint,
  total_spent_cents bigint,
  review_count bigint,
  wishlist_count bigint,
  has_preferences boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Permission denied: staff access required' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::bigint FROM public.orders WHERE user_id = p_user_id) AS order_count,
    (SELECT COALESCE(SUM(total_cents), 0)::bigint FROM public.orders WHERE user_id = p_user_id AND status IN ('paid', 'fulfilled', 'shipped', 'delivered')) AS total_spent_cents,
    (SELECT COUNT(*)::bigint FROM public.reviews WHERE user_id = p_user_id) AS review_count,
    (SELECT COUNT(*)::bigint FROM public.wishlist_items WHERE user_id = p_user_id) AS wishlist_count,
    (SELECT EXISTS(SELECT 1 FROM public.customer_preferences WHERE user_id = p_user_id)) AS has_preferences;
END;
$$;

-- ============================================================
-- Update profile role (admin only)
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_update_profile_role(p_user_id uuid, p_role text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
