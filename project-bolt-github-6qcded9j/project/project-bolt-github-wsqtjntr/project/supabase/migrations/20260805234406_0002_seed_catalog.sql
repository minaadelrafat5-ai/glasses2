/*
# Vuera — Seed Reference Data & Sample Products

## Purpose
Populates the catalog taxonomy (brands, categories, colors, frame shapes,
materials, sizes) and inserts a set of sample products with images,
variants, and category associations so the storefront has live data to
display and filter.

## What's inserted
- 2 brands (Vuera Studio, North Optics)
- 4 categories (optical, sunglasses, blue-light, readers)
- 8 colors (tortoise, matte black, crystal, gold, silver, champagne, onyx, rose)
- 7 frame shapes (round, square, rectangular, oval, cat-eye, aviator, geometric)
- 4 materials (acetate, metal, titanium, mixed)
- 6 sizes (48, 50, 52, 53, 54, 55, 58, 60 mm)
- 8 sample products, each with 3 images and 2-3 variants

## Notes
- All prices are in integer cents (e.g. 18900 = $189.00).
- Images use Pexels URLs already referenced by the static catalog.
- Products are linked to categories via the product_categories join table.
- This migration is idempotent: it uses ON CONFLICT to skip existing rows.
*/

-- Brands
INSERT INTO public.brands (name, slug, description) VALUES
  ('Vuera Studio', 'vuera-studio', 'In-house designed frames crafted in Italy.'),
  ('North Optics', 'north-optics', 'Minimalist eyewear from sustainable materials.')
ON CONFLICT (slug) DO NOTHING;

-- Categories
INSERT INTO public.categories (slug, name, description, parent_id) VALUES
  ('optical', 'Optical', 'Prescription frames for everyday clarity.', NULL),
  ('sunglasses', 'Sunglasses', 'UV-protected shades in timeless silhouettes.', NULL),
  ('blue-light', 'Blue Light', 'Screen-friendly lenses for digital days.', NULL),
  ('readers', 'Readers', 'Magnifying frames for close-up focus.', NULL)
ON CONFLICT (slug) DO NOTHING;

-- Colors
INSERT INTO public.colors (name, slug, hex_code) VALUES
  ('Tortoise', 'tortoise', '#8B5A2B'),
  ('Matte Black', 'matte-black', '#1A1A1A'),
  ('Crystal', 'crystal', '#E8E8E8'),
  ('Gold', 'gold', '#D4AF37'),
  ('Silver', 'silver', '#C0C0C0'),
  ('Champagne', 'champagne', '#F7E7CE'),
  ('Onyx', 'onyx', '#0A0A0A'),
  ('Rose', 'rose', '#E8B4B8'),
  ('Gunmetal', 'gunmetal', '#4A4A4A')
ON CONFLICT (slug) DO NOTHING;

-- Frame shapes
INSERT INTO public.frame_shapes (slug, name) VALUES
  ('round', 'Round'),
  ('square', 'Square'),
  ('rectangular', 'Rectangular'),
  ('oval', 'Oval'),
  ('cat-eye', 'Cat-eye'),
  ('aviator', 'Aviator'),
  ('geometric', 'Geometric')
ON CONFLICT (slug) DO NOTHING;

-- Materials
INSERT INTO public.materials (slug, name) VALUES
  ('acetate', 'Acetate'),
  ('metal', 'Metal'),
  ('titanium', 'Titanium'),
  ('mixed', 'Mixed')
ON CONFLICT (slug) DO NOTHING;

-- Sizes
INSERT INTO public.sizes (size_mm, label) VALUES
  (48, '48mm'),
  (50, '50mm'),
  (52, '52mm'),
  (53, '53mm'),
  (54, '54mm'),
  (55, '55mm'),
  (58, '58mm'),
  (60, '60mm')
ON CONFLICT (size_mm) DO NOTHING;

-- Helper: get IDs by slug
DO $$
DECLARE
  v_brand_vuera uuid := (SELECT id FROM public.brands WHERE slug = 'vuera-studio');
  v_brand_north uuid := (SELECT id FROM public.brands WHERE slug = 'north-optics');
  v_shape_cat uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'cat-eye');
  v_shape_avi uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'aviator');
  v_shape_round uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'round');
  v_shape_geo uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'geometric');
  v_shape_sq uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'square');
  v_shape_oval uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'oval');
  v_shape_rect uuid := (SELECT id FROM public.frame_shapes WHERE slug = 'rectangular');
  v_mat_acetate uuid := (SELECT id FROM public.materials WHERE slug = 'acetate');
  v_mat_metal uuid := (SELECT id FROM public.materials WHERE slug = 'metal');
  v_mat_titanium uuid := (SELECT id FROM public.materials WHERE slug = 'titanium');
  v_color_tortoise uuid := (SELECT id FROM public.colors WHERE slug = 'tortoise');
  v_color_black uuid := (SELECT id FROM public.colors WHERE slug = 'matte-black');
  v_color_crystal uuid := (SELECT id FROM public.colors WHERE slug = 'crystal');
  v_color_gold uuid := (SELECT id FROM public.colors WHERE slug = 'gold');
  v_color_silver uuid := (SELECT id FROM public.colors WHERE slug = 'silver');
  v_color_champagne uuid := (SELECT id FROM public.colors WHERE slug = 'champagne');
  v_color_onyx uuid := (SELECT id FROM public.colors WHERE slug = 'onyx');
  v_color_rose uuid := (SELECT id FROM public.colors WHERE slug = 'rose');
  v_color_gunmetal uuid := (SELECT id FROM public.colors WHERE slug = 'gunmetal');
  v_size_48 uuid := (SELECT id FROM public.sizes WHERE size_mm = 48);
  v_size_50 uuid := (SELECT id FROM public.sizes WHERE size_mm = 50);
  v_size_52 uuid := (SELECT id FROM public.sizes WHERE size_mm = 52);
  v_size_53 uuid := (SELECT id FROM public.sizes WHERE size_mm = 53);
  v_size_54 uuid := (SELECT id FROM public.sizes WHERE size_mm = 54);
  v_size_55 uuid := (SELECT id FROM public.sizes WHERE size_mm = 55);
  v_size_58 uuid := (SELECT id FROM public.sizes WHERE size_mm = 58);
  v_size_60 uuid := (SELECT id FROM public.sizes WHERE size_mm = 60);
  v_cat_optical uuid := (SELECT id FROM public.categories WHERE slug = 'optical');
  v_cat_sunglasses uuid := (SELECT id FROM public.categories WHERE slug = 'sunglasses');
  v_cat_bluelight uuid := (SELECT id FROM public.categories WHERE slug = 'blue-light');
  v_cat_readers uuid := (SELECT id FROM public.categories WHERE slug = 'readers');
  v_p_aurora uuid;
  v_p_meridian uuid;
  v_p_atlas uuid;
  v_p_nova uuid;
  v_p_horizon uuid;
  v_p_lumina uuid;
  v_p_orbit uuid;
  v_p_eclipse uuid;
BEGIN
  -- Aurora (cat-eye, acetate, women, optical+sunglasses)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('aurora-cat-eye', 'Aurora', v_brand_vuera,
    'A sculpted cat-eye frame with a subtle upswept brow line. Hand-polished Italian acetate with stainless steel hinges.',
    v_shape_cat, v_mat_acetate, 'women', 'single-vision', 18900, NULL, 'active', 4.8, 124)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_aurora;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_aurora, 'https://images.pexels.com/photos/29811438/pexels-photo-29811438.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Aurora cat-eye frame on silk', 0, false),
    (v_p_aurora, 'https://images.pexels.com/photos/26100579/pexels-photo-26100579.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Model wearing Aurora frames', 1, false),
    (v_p_aurora, 'https://images.pexels.com/photos/29811437/pexels-photo-29811437.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Aurora frame detail with gold accents', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_aurora, v_color_tortoise, v_size_52, 'Tortoise / 52mm', NULL, 18900, 18, 'VU-AUR-TT-52'),
    (v_p_aurora, v_color_black, v_size_52, 'Matte Black / 52mm', NULL, 18900, 12, 'VU-AUR-BK-52'),
    (v_p_aurora, v_color_crystal, v_size_50, 'Crystal / 50mm', NULL, 19900, 8, 'VU-AUR-CR-50')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_aurora, v_cat_optical), (v_p_aurora, v_cat_sunglasses)
  ON CONFLICT DO NOTHING;

  -- Meridian (aviator, metal, unisex, sunglasses)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('meridian-aviator', 'Meridian', v_brand_vuera,
    'A modern take on the classic aviator. Lightweight titanium frame with gradient polarized lenses.',
    v_shape_avi, v_mat_metal, 'unisex', 'sunglasses', 21900, NULL, 'active', 4.6, 89)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_meridian;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_meridian, 'https://images.pexels.com/photos/16625257/pexels-photo-16625257.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Meridian aviator sunglasses', 0, false),
    (v_p_meridian, 'https://images.pexels.com/photos/29271917/pexels-photo-29271917.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Model wearing Meridian sunglasses', 1, false),
    (v_p_meridian, 'https://images.pexels.com/photos/14464892/pexels-photo-14464892.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Meridian sunglasses urban setting', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_meridian, v_color_gold, v_size_58, 'Gold / Green Lens', 'Green', 21900, 22, 'VU-MER-GD-GR'),
    (v_p_meridian, v_color_silver, v_size_58, 'Silver / Grey Lens', 'Grey', 21900, 15, 'VU-MER-SV-GY'),
    (v_p_meridian, v_color_black, v_size_58, 'Black / Smoke Lens', 'Smoke', 22900, 10, 'VU-MER-BK-SM')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_meridian, v_cat_sunglasses)
  ON CONFLICT DO NOTHING;

  -- Atlas (round, acetate, unisex, optical+blue-light) — on sale
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('atlas-round', 'Atlas', v_brand_north,
    'Perfectly round lenses in a chunky acetate frame. A statement piece inspired by 1960s intellectuals.',
    v_shape_round, v_mat_acetate, 'unisex', 'single-vision', 12900, 15900, 'active', 4.4, 67)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_atlas;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_atlas, 'https://images.pexels.com/photos/36310717/pexels-photo-36310717.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Atlas round frame on stand', 0, false),
    (v_p_atlas, 'https://images.pexels.com/photos/36713202/pexels-photo-36713202.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Model wearing round Atlas frames', 1, false),
    (v_p_atlas, 'https://images.pexels.com/photos/36713201/pexels-photo-36713201.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Atlas frame close-up', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_atlas, v_color_crystal, v_size_48, 'Crystal / 48mm', NULL, 12900, 30, 'VU-ATL-CR-48'),
    (v_p_atlas, v_color_black, v_size_48, 'Matte Black / 48mm', NULL, 12900, 25, 'VU-ATL-BK-48')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_atlas, v_cat_optical), (v_p_atlas, v_cat_bluelight)
  ON CONFLICT DO NOTHING;

  -- Nova (geometric, acetate, women, optical+sunglasses)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('nova-geometric', 'Nova', v_brand_vuera,
    'Bold geometric silhouette with sharp angular lines. For those who refuse to blend in.',
    v_shape_geo, v_mat_acetate, 'women', 'single-vision', 20900, NULL, 'active', 4.9, 156)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_nova;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_nova, 'https://images.pexels.com/photos/29301758/pexels-photo-29301758.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Nova geometric sunglasses', 0, false),
    (v_p_nova, 'https://images.pexels.com/photos/26100579/pexels-photo-26100579.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Model wearing Nova frames', 1, false),
    (v_p_nova, 'https://images.pexels.com/photos/31762856/pexels-photo-31762856.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Nova sunglasses indoor', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_nova, v_color_champagne, v_size_53, 'Champagne / 53mm', NULL, 20900, 14, 'VU-NOV-CH-53'),
    (v_p_nova, v_color_onyx, v_size_53, 'Onyx / 53mm', NULL, 20900, 9, 'VU-NOV-ON-53')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_nova, v_cat_optical), (v_p_nova, v_cat_sunglasses)
  ON CONFLICT DO NOTHING;

  -- Horizon (square, titanium, men, optical+blue-light)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('horizon-square', 'Horizon', v_brand_north,
    'Architectural square frame in featherlight titanium. Clean lines for a confident, modern look.',
    v_shape_sq, v_mat_titanium, 'men', 'single-vision', 17900, NULL, 'active', 4.5, 92)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_horizon;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_horizon, 'https://images.pexels.com/photos/19552285/pexels-photo-19552285.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Horizon square frame portrait', 0, false),
    (v_p_horizon, 'https://images.pexels.com/photos/1743545/pexels-photo-1743545.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Man wearing Horizon frames', 1, false),
    (v_p_horizon, 'https://images.pexels.com/photos/17065258/pexels-photo-17065258.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Horizon frame close-up', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_horizon, v_color_gunmetal, v_size_54, 'Gunmetal / 54mm', NULL, 17900, 20, 'VU-HOR-GM-54'),
    (v_p_horizon, v_color_black, v_size_54, 'Matte Black / 54mm', NULL, 17900, 16, 'VU-HOR-BK-54')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_horizon, v_cat_optical), (v_p_horizon, v_cat_bluelight)
  ON CONFLICT DO NOTHING;

  -- Lumina (oval, acetate, women, optical+readers) — on sale
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('lumina-oval', 'Lumina', v_brand_vuera,
    'Soft oval frame with a gentle keyhole bridge. Universally flattering and impossibly light.',
    v_shape_oval, v_mat_acetate, 'women', 'single-vision', 13900, 16900, 'active', 4.7, 108)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_lumina;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_lumina, 'https://images.pexels.com/photos/8473285/pexels-photo-8473285.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Lumina oval frame still life', 0, false),
    (v_p_lumina, 'https://images.pexels.com/photos/7860704/pexels-photo-7860704.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Woman wearing Lumina frames', 1, false),
    (v_p_lumina, 'https://images.pexels.com/photos/38453638/pexels-photo-38453638.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Lumina frame profile view', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_lumina, v_color_rose, v_size_50, 'Rose / 51mm', NULL, 13900, 28, 'VU-LUM-RS-51'),
    (v_p_lumina, v_color_black, v_size_50, 'Matte Black / 51mm', NULL, 13900, 19, 'VU-LUM-BK-51'),
    (v_p_lumina, v_color_tortoise, v_size_50, 'Tortoise / 51mm', NULL, 14900, 11, 'VU-LUM-TT-51')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_lumina, v_cat_optical), (v_p_lumina, v_cat_readers)
  ON CONFLICT DO NOTHING;

  -- Orbit (rectangular, metal, men, optical+blue-light)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('orbit-rectangular', 'Orbit', v_brand_north,
    'Slim rectangular frame with a brushed metal finish. Understated and endlessly versatile.',
    v_shape_rect, v_mat_metal, 'men', 'single-vision', 14900, NULL, 'active', 4.3, 54)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_orbit;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_orbit, 'https://images.pexels.com/photos/16764124/pexels-photo-16764124.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Orbit rectangular frame portrait', 0, false),
    (v_p_orbit, 'https://images.pexels.com/photos/14228163/pexels-photo-14228163.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Man adjusting Orbit frames', 1, false),
    (v_p_orbit, 'https://images.pexels.com/photos/5914908/pexels-photo-5914908.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Orbit frame outdoor', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_orbit, v_color_silver, v_size_55, 'Silver / 55mm', NULL, 14900, 24, 'VU-ORB-SV-55'),
    (v_p_orbit, v_color_black, v_size_55, 'Black / 55mm', NULL, 14900, 17, 'VU-ORB-BK-55')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_orbit, v_cat_optical), (v_p_orbit, v_cat_bluelight)
  ON CONFLICT DO NOTHING;

  -- Eclipse (aviator, metal, unisex, sunglasses)
  INSERT INTO public.products (slug, name, brand_id, description, shape_id, material_id, gender, lens_type, price_cents, compare_at_price_cents, status, rating, review_count)
  VALUES ('eclipse-aviator', 'Eclipse', v_brand_vuera,
    'Oversized aviator with a double bridge and mirrored lenses. Maximum coverage, maximum impact.',
    v_shape_avi, v_mat_metal, 'unisex', 'sunglasses', 23900, NULL, 'active', 4.8, 73)
  ON CONFLICT (slug) DO NOTHING
  RETURNING id INTO v_p_eclipse;

  INSERT INTO public.product_images (product_id, url, alt_text, position, is_ai_generated) VALUES
    (v_p_eclipse, 'https://images.pexels.com/photos/38523258/pexels-photo-38523258.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Eclipse aviator sunglasses', 0, false),
    (v_p_eclipse, 'https://images.pexels.com/photos/18742635/pexels-photo-18742635.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Model wearing Eclipse sunglasses profile', 1, false),
    (v_p_eclipse, 'https://images.pexels.com/photos/5891808/pexels-photo-5891808.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'Eclipse sunglasses street style', 2, false)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.product_variants (product_id, color_id, size_id, name, lens_tint, price_cents, stock, sku) VALUES
    (v_p_eclipse, v_color_gold, v_size_60, 'Gold / Mirror Lens', 'Mirror', 23900, 13, 'VU-ECL-GD-MR'),
    (v_p_eclipse, v_color_black, v_size_60, 'Black / Smoke Lens', 'Smoke', 23900, 9, 'VU-ECL-BK-SM')
  ON CONFLICT (sku) DO NOTHING;

  INSERT INTO public.product_categories (product_id, category_id) VALUES
    (v_p_eclipse, v_cat_sunglasses)
  ON CONFLICT DO NOTHING;
END $$;
