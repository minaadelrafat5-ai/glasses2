/*
# Vuera — Core Foundation Schema

Establishes the complete production data model for the Vuera eyewear
e-commerce platform: users (customer / admin / staff), products and their
full attribute taxonomy (brands, categories, colors, frame shapes,
materials, sizes, images, variants, prices, stock), the shopping system
(cart, wishlist, orders, order items, reviews), customer preferences, and
placeholder tables for future AI features (AR try-on, AI-generated images,
AI recommendations).

## New Tables
- profiles, user_addresses
- brands, categories, colors, frame_shapes, materials, sizes
- products, product_images, product_variants, product_categories
- cart_items, wishlist_items, orders, order_items
- reviews
- customer_preferences
- ai_tryon_requests, ai_recommendation_requests

## Security (RLS)
- RLS enabled on EVERY table.
- Profiles: own SELECT/UPDATE/INSERT; staff can read all.
- Catalog tables: public read; write restricted to admin/staff via is_staff().
- Cart & wishlist: owner-scoped CRUD.
- Orders: customer reads own; staff reads all.
- Customer preferences: owner-scoped CRUD.
- AI request tables: owner-scoped SELECT/INSERT; staff can read all.

## Notes
1. profiles.role CHECK ('customer','admin','staff'), default 'customer'.
2. Owner columns default to auth.uid().
3. Money columns are integer cents.
4. is_staff() SECURITY DEFINER helper is the single source of staff auth.
*/

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role
  FROM public.profiles
  WHERE id = auth.uid();
  RETURN v_role IN ('admin', 'staff');
END;
$$;

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  first_name text,
  last_name text,
  role text NOT NULL DEFAULT 'customer'
    CHECK (role IN ('customer', 'admin', 'staff')),
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_profile" ON public.profiles;
CREATE POLICY "select_own_profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id OR public.is_staff());
DROP POLICY IF EXISTS "insert_own_profile" ON public.profiles;
CREATE POLICY "insert_own_profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "update_own_profile" ON public.profiles;
CREATE POLICY "update_own_profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE TABLE IF NOT EXISTS public.user_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  label text, full_name text NOT NULL, line1 text NOT NULL, line2 text,
  city text NOT NULL, state text NOT NULL, postal_code text NOT NULL,
  country text NOT NULL DEFAULT 'US', phone text, is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.user_addresses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_addresses" ON public.user_addresses;
CREATE POLICY "select_own_addresses" ON public.user_addresses FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_addresses" ON public.user_addresses;
CREATE POLICY "insert_own_addresses" ON public.user_addresses FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_addresses" ON public.user_addresses;
CREATE POLICY "update_own_addresses" ON public.user_addresses FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_addresses" ON public.user_addresses;
CREATE POLICY "delete_own_addresses" ON public.user_addresses FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.brands (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL UNIQUE, slug text NOT NULL UNIQUE, description text, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_brands" ON public.brands;
CREATE POLICY "read_brands" ON public.brands FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_brands" ON public.brands;
CREATE POLICY "staff_write_brands" ON public.brands FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.categories (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), slug text NOT NULL UNIQUE, name text NOT NULL, description text, parent_id uuid REFERENCES public.categories(id) ON DELETE SET NULL, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_categories" ON public.categories;
CREATE POLICY "read_categories" ON public.categories FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_categories" ON public.categories;
CREATE POLICY "staff_write_categories" ON public.categories FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.colors (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL UNIQUE, slug text NOT NULL UNIQUE, hex_code text, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.colors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_colors" ON public.colors;
CREATE POLICY "read_colors" ON public.colors FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_colors" ON public.colors;
CREATE POLICY "staff_write_colors" ON public.colors FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.frame_shapes (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), slug text NOT NULL UNIQUE, name text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.frame_shapes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_frame_shapes" ON public.frame_shapes;
CREATE POLICY "read_frame_shapes" ON public.frame_shapes FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_frame_shapes" ON public.frame_shapes;
CREATE POLICY "staff_write_frame_shapes" ON public.frame_shapes FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.materials (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), slug text NOT NULL UNIQUE, name text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_materials" ON public.materials;
CREATE POLICY "read_materials" ON public.materials FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_materials" ON public.materials;
CREATE POLICY "staff_write_materials" ON public.materials FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.sizes (id uuid PRIMARY KEY DEFAULT gen_random_uuid(), size_mm integer NOT NULL UNIQUE CHECK (size_mm > 0 AND size_mm < 100), label text NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.sizes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_sizes" ON public.sizes;
CREATE POLICY "read_sizes" ON public.sizes FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_sizes" ON public.sizes;
CREATE POLICY "staff_write_sizes" ON public.sizes FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE, name text NOT NULL,
  brand_id uuid REFERENCES public.brands(id) ON DELETE SET NULL,
  description text,
  shape_id uuid REFERENCES public.frame_shapes(id) ON DELETE SET NULL,
  material_id uuid REFERENCES public.materials(id) ON DELETE SET NULL,
  gender text NOT NULL DEFAULT 'unisex' CHECK (gender IN ('unisex', 'men', 'women')),
  lens_type text NOT NULL DEFAULT 'single-vision' CHECK (lens_type IN ('single-vision', 'progressive', 'reading', 'non-prescription', 'sunglasses')),
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  compare_at_price_cents integer CHECK (compare_at_price_cents >= 0),
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'draft', 'archived')),
  rating numeric(2,1), review_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_products" ON public.products;
CREATE POLICY "read_products" ON public.products FOR SELECT TO anon, authenticated USING (status = 'active' OR public.is_staff());
DROP POLICY IF EXISTS "staff_write_products" ON public.products;
CREATE POLICY "staff_write_products" ON public.products FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.product_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  url text NOT NULL, alt_text text, position integer NOT NULL DEFAULT 0,
  is_ai_generated boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_product_images" ON public.product_images;
CREATE POLICY "read_product_images" ON public.product_images FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_product_images" ON public.product_images;
CREATE POLICY "staff_write_product_images" ON public.product_images FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.product_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  color_id uuid REFERENCES public.colors(id) ON DELETE SET NULL,
  size_id uuid REFERENCES public.sizes(id) ON DELETE SET NULL,
  name text NOT NULL, lens_tint text,
  price_cents integer NOT NULL CHECK (price_cents >= 0),
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  sku text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_product_variants" ON public.product_variants;
CREATE POLICY "read_product_variants" ON public.product_variants FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_product_variants" ON public.product_variants;
CREATE POLICY "staff_write_product_variants" ON public.product_variants FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.product_categories (
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  category_id uuid NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  PRIMARY KEY (product_id, category_id)
);
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_product_categories" ON public.product_categories;
CREATE POLICY "read_product_categories" ON public.product_categories FOR SELECT TO anon, authenticated USING (true);
DROP POLICY IF EXISTS "staff_write_product_categories" ON public.product_categories;
CREATE POLICY "staff_write_product_categories" ON public.product_categories FOR ALL TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  variant_id uuid NOT NULL REFERENCES public.product_variants(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, variant_id)
);
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_cart" ON public.cart_items;
CREATE POLICY "select_own_cart" ON public.cart_items FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_cart" ON public.cart_items;
CREATE POLICY "insert_own_cart" ON public.cart_items FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_cart" ON public.cart_items;
CREATE POLICY "update_own_cart" ON public.cart_items FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_cart" ON public.cart_items;
CREATE POLICY "delete_own_cart" ON public.cart_items FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.wishlist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(), UNIQUE (user_id, product_id)
);
ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_wishlist" ON public.wishlist_items;
CREATE POLICY "select_own_wishlist" ON public.wishlist_items FOR SELECT TO authenticated USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "insert_own_wishlist" ON public.wishlist_items;
CREATE POLICY "insert_own_wishlist" ON public.wishlist_items FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_wishlist" ON public.wishlist_items;
CREATE POLICY "delete_own_wishlist" ON public.wishlist_items FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'fulfilled', 'shipped', 'delivered', 'cancelled', 'refunded')),
  subtotal_cents integer NOT NULL DEFAULT 0 CHECK (subtotal_cents >= 0),
  shipping_cents integer NOT NULL DEFAULT 0 CHECK (shipping_cents >= 0),
  tax_cents integer NOT NULL DEFAULT 0 CHECK (tax_cents >= 0),
  total_cents integer NOT NULL DEFAULT 0 CHECK (total_cents >= 0),
  currency text NOT NULL DEFAULT 'USD', shipping_address jsonb,
  customer_email text,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_orders" ON public.orders;
CREATE POLICY "select_own_orders" ON public.orders FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_staff());
DROP POLICY IF EXISTS "staff_update_orders" ON public.orders;
CREATE POLICY "staff_update_orders" ON public.orders FOR UPDATE TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  variant_id uuid REFERENCES public.product_variants(id) ON DELETE SET NULL,
  product_name text NOT NULL, variant_name text NOT NULL,
  unit_price_cents integer NOT NULL CHECK (unit_price_cents >= 0),
  quantity integer NOT NULL CHECK (quantity > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_order_items" ON public.order_items;
CREATE POLICY "select_own_order_items" ON public.order_items FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND (o.user_id = auth.uid() OR public.is_staff())));

CREATE TABLE IF NOT EXISTS public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  author_name text NOT NULL, rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  title text NOT NULL, body text NOT NULL, verified_purchase boolean NOT NULL DEFAULT false,
  moderation_status text NOT NULL DEFAULT 'pending' CHECK (moderation_status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "read_approved_reviews" ON public.reviews;
CREATE POLICY "read_approved_reviews" ON public.reviews FOR SELECT TO anon, authenticated USING (moderation_status = 'approved' OR auth.uid() = user_id OR public.is_staff());
DROP POLICY IF EXISTS "insert_own_review" ON public.reviews;
CREATE POLICY "insert_own_review" ON public.reviews FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_review" ON public.reviews;
CREATE POLICY "update_own_review" ON public.reviews FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "staff_update_reviews" ON public.reviews;
CREATE POLICY "staff_update_reviews" ON public.reviews FOR UPDATE TO authenticated USING (public.is_staff()) WITH CHECK (public.is_staff());
DROP POLICY IF EXISTS "delete_own_review" ON public.reviews;
CREATE POLICY "delete_own_review" ON public.reviews FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.customer_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  style_prompt text, budget_cents integer CHECK (budget_cents IS NULL OR budget_cents >= 0),
  face_profile jsonb, preferred_shapes text[] DEFAULT '{}', preferred_materials text[] DEFAULT '{}', preferred_colors text[] DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(), UNIQUE (user_id)
);
ALTER TABLE public.customer_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_preferences" ON public.customer_preferences;
CREATE POLICY "select_own_preferences" ON public.customer_preferences FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_staff());
DROP POLICY IF EXISTS "insert_own_preferences" ON public.customer_preferences;
CREATE POLICY "insert_own_preferences" ON public.customer_preferences FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "update_own_preferences" ON public.customer_preferences;
CREATE POLICY "update_own_preferences" ON public.customer_preferences FOR UPDATE TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "delete_own_preferences" ON public.customer_preferences;
CREATE POLICY "delete_own_preferences" ON public.customer_preferences FOR DELETE TO authenticated USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.ai_tryon_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  variant_id uuid REFERENCES public.product_variants(id) ON DELETE SET NULL,
  source_image_url text NOT NULL, result_image_url text, fit_confidence numeric(3,2),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_tryon_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_tryon" ON public.ai_tryon_requests;
CREATE POLICY "select_own_tryon" ON public.ai_tryon_requests FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_staff());
DROP POLICY IF EXISTS "insert_own_tryon" ON public.ai_tryon_requests;
CREATE POLICY "insert_own_tryon" ON public.ai_tryon_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.ai_recommendation_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id) ON DELETE CASCADE,
  prompt text NOT NULL, result jsonb,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.ai_recommendation_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "select_own_recommendations" ON public.ai_recommendation_requests;
CREATE POLICY "select_own_recommendations" ON public.ai_recommendation_requests FOR SELECT TO authenticated USING (auth.uid() = user_id OR public.is_staff());
DROP POLICY IF EXISTS "insert_own_recommendations" ON public.ai_recommendation_requests;
CREATE POLICY "insert_own_recommendations" ON public.ai_recommendation_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_products_brand_id ON public.products(brand_id);
CREATE INDEX IF NOT EXISTS idx_products_shape_id ON public.products(shape_id);
CREATE INDEX IF NOT EXISTS idx_products_material_id ON public.products(material_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON public.products(status);
CREATE INDEX IF NOT EXISTS idx_products_lens_type ON public.products(lens_type);
CREATE INDEX IF NOT EXISTS idx_products_gender ON public.products(gender);
CREATE INDEX IF NOT EXISTS idx_products_price ON public.products(price_cents);
CREATE INDEX IF NOT EXISTS idx_products_rating ON public.products(rating DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_product_images_product_id ON public.product_images(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON public.product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON public.product_variants(sku);
CREATE INDEX IF NOT EXISTS idx_product_variants_color_id ON public.product_variants(color_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_size_id ON public.product_variants(size_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_category_id ON public.product_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_product_categories_product_id ON public.product_categories(product_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON public.cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_items_user_id ON public.wishlist_items(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_moderation ON public.reviews(moderation_status);
CREATE INDEX IF NOT EXISTS idx_user_addresses_user_id ON public.user_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_tryon_user_id ON public.ai_tryon_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_recommendation_user_id ON public.ai_recommendation_requests(user_id);

CREATE OR REPLACE FUNCTION public.touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at := now(); RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_user_addresses_updated_at ON public.user_addresses;
CREATE TRIGGER trg_user_addresses_updated_at BEFORE UPDATE ON public.user_addresses FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_products_updated_at ON public.products;
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_product_variants_updated_at ON public.product_variants;
CREATE TRIGGER trg_product_variants_updated_at BEFORE UPDATE ON public.product_variants FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_reviews_updated_at ON public.reviews;
CREATE TRIGGER trg_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_customer_preferences_updated_at ON public.customer_preferences;
CREATE TRIGGER trg_customer_preferences_updated_at BEFORE UPDATE ON public.customer_preferences FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();
DROP TRIGGER IF EXISTS trg_ai_tryon_updated_at ON public.ai_tryon_requests;
CREATE TRIGGER trg_ai_tryon_updated_at BEFORE UPDATE ON public.ai_tryon_requests FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN INSERT INTO public.profiles (id, email, role) VALUES (NEW.id, NEW.email, 'customer') ON CONFLICT (id) DO NOTHING; RETURN NEW; END; $$;
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
