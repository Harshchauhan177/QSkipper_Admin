-- ============================================
-- QSkipper Admin — Supabase Database Setup
-- ============================================
-- Run this ENTIRE script in your Supabase SQL Editor
-- (Dashboard > SQL Editor > New Query > Paste & Run)
-- ============================================

-- ============================================
-- 1. RESTAURANTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS restaurants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '',
    cuisine TEXT DEFAULT '',
    estimated_time INTEGER DEFAULT 30,
    banner_image_url TEXT,
    rating NUMERIC(3,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. PRODUCTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name TEXT NOT NULL DEFAULT '',
    price NUMERIC(10,2) NOT NULL DEFAULT 0,
    category TEXT DEFAULT '',
    description TEXT DEFAULT '',
    extra_time INTEGER DEFAULT 0,
    rating NUMERIC(3,2) DEFAULT 0,
    is_available BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    image_url TEXT,
    quantity INTEGER DEFAULT 0,
    top_picks BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 3. ORDERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'pending',
    cook_time INTEGER DEFAULT 0,
    take_away BOOLEAN DEFAULT false,
    schedule_date TIMESTAMPTZ,
    order_time TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 4. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    name TEXT NOT NULL DEFAULT '',
    quantity INTEGER NOT NULL DEFAULT 1,
    price NUMERIC(10,2) NOT NULL DEFAULT 0
);

-- ============================================
-- 5. AUTO-UPDATE updated_at TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_restaurants_updated_at
    BEFORE UPDATE ON restaurants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- --- RESTAURANTS ---
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can do everything with own restaurants"
    ON restaurants FOR ALL
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Anyone can view active restaurants"
    ON restaurants FOR SELECT
    USING (is_active = true);

-- --- PRODUCTS ---
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view products"
    ON products FOR SELECT
    USING (true);

CREATE POLICY "Owners can insert products to own restaurants"
    ON products FOR INSERT
    WITH CHECK (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    );

CREATE POLICY "Owners can update own restaurant products"
    ON products FOR UPDATE
    USING (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    )
    WITH CHECK (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    );

CREATE POLICY "Owners can delete own restaurant products"
    ON products FOR DELETE
    USING (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    );

-- --- ORDERS ---
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view their orders"
    ON orders FOR SELECT
    USING (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
        OR user_id = auth.uid()
    );

CREATE POLICY "Users can create orders"
    ON orders FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Restaurant owners can update order status"
    ON orders FOR UPDATE
    USING (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    )
    WITH CHECK (
        restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
    );

-- --- ORDER ITEMS ---
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Access order items via order access"
    ON order_items FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM orders WHERE
                restaurant_id IN (SELECT id FROM restaurants WHERE owner_id = auth.uid())
                OR user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert order items"
    ON order_items FOR INSERT
    WITH CHECK (
        order_id IN (SELECT id FROM orders WHERE user_id = auth.uid())
    );

-- ============================================
-- 7. STORAGE BUCKETS FOR IMAGES
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('restaurant-images', 'restaurant-images', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies: Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload restaurant images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'restaurant-images');

CREATE POLICY "Authenticated users can update restaurant images"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'restaurant-images');

CREATE POLICY "Anyone can view restaurant images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'restaurant-images');

CREATE POLICY "Authenticated users can delete restaurant images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'restaurant-images');

CREATE POLICY "Authenticated users can upload product images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can update product images"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'product-images');

CREATE POLICY "Anyone can view product images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can delete product images"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'product-images');

-- ============================================
-- 8. HELPER FUNCTION: Get restaurant for current user
-- ============================================
CREATE OR REPLACE FUNCTION get_my_restaurant()
RETURNS SETOF restaurants
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT * FROM restaurants WHERE owner_id = auth.uid() LIMIT 1;
$$;

-- ============================================
-- DONE! Your database is ready.
-- ============================================
