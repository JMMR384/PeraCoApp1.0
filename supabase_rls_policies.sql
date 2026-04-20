-- ================================================================
-- PERACO — ROW LEVEL SECURITY POLICIES
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Versión: 1.0 | Fecha: 2026-04-19
-- ================================================================
-- IMPORTANTE: Ejecutar completo de una vez (no por partes)
-- Si alguna tabla no existe, comentar su bloque y ejecutar el resto
-- ================================================================

-- ================================================================
-- NOTA CORS (Supabase Docker + ngrok)
-- ================================================================
-- Supabase local (Docker) no tiene CORS configurable desde SQL.
-- Para configurar CORS en la instancia Docker:
--
-- Opción A — supabase/config.toml (si usas Supabase CLI):
--   [api]
--   extra_search_path = ["public", "extensions"]
--   [api.cors]
--   allowed_origins = [
--     "https://samantha-nemoricole-nontyrannously.ngrok-free.dev",
--     "http://localhost:54321",
--     "http://10.0.2.2:54321",
--     "com.peracoo.peraco://"
--   ]
--
-- Opción B — docker-compose.yml (variable de entorno Kong/PostgREST):
--   environment:
--     PGRST_SERVER_CORS_ALLOWED_ORIGINS: "https://samantha-nemoricole-nontyrannously.ngrok-free.dev,http://localhost:54321"
--
-- CUANDO CAMBIE LA URL DE NGROK:
--   1. Actualizar .env → SUPABASE_URL=https://nueva-url.ngrok-free.dev
--   2. Actualizar allowed_origins en config.toml o docker-compose.yml
--   3. Reiniciar contenedores: docker compose restart kong
--   4. La app Flutter tomará la nueva URL en el próximo hot-restart
-- ================================================================


-- ================================================================
-- 1. USUARIOS — Cada usuario solo lee/edita su propio registro
-- ================================================================
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "usuarios_select_own"  ON usuarios;
DROP POLICY IF EXISTS "usuarios_insert_own"  ON usuarios;
DROP POLICY IF EXISTS "usuarios_update_own"  ON usuarios;

-- Lectura: solo el propio usuario (signup_screen necesita leer su row tras crear cuenta)
CREATE POLICY "usuarios_select_own" ON usuarios
  FOR SELECT USING (auth.uid() = id);

-- Insert: solo puede insertar su propio registro (auth.uid() debe coincidir con id)
CREATE POLICY "usuarios_insert_own" ON usuarios
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Update: solo el propio usuario puede editar
CREATE POLICY "usuarios_update_own" ON usuarios
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);


-- ================================================================
-- 2. INFO_VENDEDOR — Lectura pública (para mostrar nombre_negocio en productos),
--    escritura solo del dueño
-- ================================================================
ALTER TABLE info_vendedor ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "info_vendedor_public_read"  ON info_vendedor;
DROP POLICY IF EXISTS "info_vendedor_insert_own"   ON info_vendedor;
DROP POLICY IF EXISTS "info_vendedor_update_own"   ON info_vendedor;

CREATE POLICY "info_vendedor_public_read" ON info_vendedor
  FOR SELECT USING (true);

CREATE POLICY "info_vendedor_insert_own" ON info_vendedor
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "info_vendedor_update_own" ON info_vendedor
  FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);


-- ================================================================
-- 3. INFO_FISCAL — Solo el dueño lee/escribe (datos sensibles NIT/RUT)
-- ================================================================
ALTER TABLE info_fiscal ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "info_fiscal_select_own" ON info_fiscal;
DROP POLICY IF EXISTS "info_fiscal_insert_own" ON info_fiscal;
DROP POLICY IF EXISTS "info_fiscal_update_own" ON info_fiscal;

CREATE POLICY "info_fiscal_select_own" ON info_fiscal
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "info_fiscal_insert_own" ON info_fiscal
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "info_fiscal_update_own" ON info_fiscal
  FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);


-- ================================================================
-- 4. INFO_PERAGOGER — Solo el dueño lee/escribe
-- ================================================================
ALTER TABLE info_peragoger ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "info_peragoger_select_own" ON info_peragoger;
DROP POLICY IF EXISTS "info_peragoger_insert_own" ON info_peragoger;
DROP POLICY IF EXISTS "info_peragoger_update_own" ON info_peragoger;

CREATE POLICY "info_peragoger_select_own" ON info_peragoger
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "info_peragoger_insert_own" ON info_peragoger
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "info_peragoger_update_own" ON info_peragoger
  FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);


-- ================================================================
-- 5. CATEGORIAS — Solo lectura pública (catálogo de categorías)
-- ================================================================
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "categorias_public_read" ON categorias;

CREATE POLICY "categorias_public_read" ON categorias
  FOR SELECT USING (true);


-- ================================================================
-- 6. PRODUCTOS — Lectura pública de activos, CRUD solo del vendedor_id
-- ================================================================
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "productos_public_read"    ON productos;
DROP POLICY IF EXISTS "productos_vendor_insert"  ON productos;
DROP POLICY IF EXISTS "productos_vendor_update"  ON productos;
DROP POLICY IF EXISTS "productos_vendor_delete"  ON productos;

-- Todos ven productos activos; el vendedor ve también los suyos inactivos
CREATE POLICY "productos_public_read" ON productos
  FOR SELECT USING (activo = true OR auth.uid() = vendedor_id);

-- Solo agricultores y comerciantes pueden crear productos, y solo a su nombre
CREATE POLICY "productos_vendor_insert" ON productos
  FOR INSERT WITH CHECK (
    auth.uid() = vendedor_id AND
    EXISTS (
      SELECT 1 FROM usuarios
      WHERE id = auth.uid() AND rol IN ('agricultor', 'comerciante')
    )
  );

CREATE POLICY "productos_vendor_update" ON productos
  FOR UPDATE USING (auth.uid() = vendedor_id)
  WITH CHECK (auth.uid() = vendedor_id);

CREATE POLICY "productos_vendor_delete" ON productos
  FOR DELETE USING (auth.uid() = vendedor_id);


-- ================================================================
-- 7. PRODUCTO_IMAGENES — Lectura pública, escritura solo dueño del producto
-- ================================================================
ALTER TABLE producto_imagenes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "producto_imagenes_public_read"   ON producto_imagenes;
DROP POLICY IF EXISTS "producto_imagenes_vendor_insert" ON producto_imagenes;
DROP POLICY IF EXISTS "producto_imagenes_vendor_delete" ON producto_imagenes;

CREATE POLICY "producto_imagenes_public_read" ON producto_imagenes
  FOR SELECT USING (true);

CREATE POLICY "producto_imagenes_vendor_insert" ON producto_imagenes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  );

CREATE POLICY "producto_imagenes_vendor_delete" ON producto_imagenes
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  );


-- ================================================================
-- 8. PEDIDOS
--   - Cliente: ve y crea los suyos (cliente_id)
--   - Vendedor: ve pedidos donde tiene items
--   - PeraGoger: ve pedidos asignados (peragoger_id) o disponibles para tomar
--   - PeraGoger: actualiza estado y peragoger_id del pedido
-- ================================================================
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pedidos_client_select"  ON pedidos;
DROP POLICY IF EXISTS "pedidos_client_insert"  ON pedidos;
DROP POLICY IF EXISTS "pedidos_vendor_select"  ON pedidos;
DROP POLICY IF EXISTS "pedidos_driver_select"  ON pedidos;
DROP POLICY IF EXISTS "pedidos_driver_update"  ON pedidos;

CREATE POLICY "pedidos_client_select" ON pedidos
  FOR SELECT USING (auth.uid() = cliente_id);

CREATE POLICY "pedidos_client_insert" ON pedidos
  FOR INSERT WITH CHECK (auth.uid() = cliente_id);

-- Vendedor ve pedidos donde alguno de sus productos fue comprado
CREATE POLICY "pedidos_vendor_select" ON pedidos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pedido_items pi
      WHERE pi.pedido_id = id AND pi.vendedor_id = auth.uid()
    )
  );

-- PeraGoger ve pedidos asignados a él, o pedidos sin asignar en estados tomables
CREATE POLICY "pedidos_driver_select" ON pedidos
  FOR SELECT USING (
    peragoger_id = auth.uid()
    OR (
      peragoger_id IS NULL
      AND estado IN ('confirmado', 'preparando')
      AND EXISTS (SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol = 'peragoger')
    )
  );

-- PeraGoger puede actualizar estado del pedido y asignarse (peragoger_id)
CREATE POLICY "pedidos_driver_update" ON pedidos
  FOR UPDATE USING (
    peragoger_id = auth.uid()
    OR (
      peragoger_id IS NULL
      AND EXISTS (SELECT 1 FROM usuarios u WHERE u.id = auth.uid() AND u.rol = 'peragoger')
    )
  );


-- ================================================================
-- 9. PEDIDO_ITEMS
--   - Cliente: ve items de sus pedidos, inserta al crear pedido
--   - Vendedor: ve items donde es vendedor_id
--   - PeraGoger: ve items de pedidos asignados
-- ================================================================
ALTER TABLE pedido_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pedido_items_client_select" ON pedido_items;
DROP POLICY IF EXISTS "pedido_items_client_insert" ON pedido_items;
DROP POLICY IF EXISTS "pedido_items_vendor_select" ON pedido_items;
DROP POLICY IF EXISTS "pedido_items_driver_select" ON pedido_items;

CREATE POLICY "pedido_items_client_select" ON pedido_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pedidos p WHERE p.id = pedido_id AND p.cliente_id = auth.uid()
    )
  );

CREATE POLICY "pedido_items_client_insert" ON pedido_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM pedidos p WHERE p.id = pedido_id AND p.cliente_id = auth.uid()
    )
  );

CREATE POLICY "pedido_items_vendor_select" ON pedido_items
  FOR SELECT USING (vendedor_id = auth.uid());

CREATE POLICY "pedido_items_driver_select" ON pedido_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pedidos p WHERE p.id = pedido_id AND p.peragoger_id = auth.uid()
    )
  );


-- ================================================================
-- 10. PEDIDO_TRACKING — Todos los involucrados leen,
--     todos los involucrados pueden insertar eventos
-- ================================================================
ALTER TABLE pedido_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pedido_tracking_select_involved" ON pedido_tracking;
DROP POLICY IF EXISTS "pedido_tracking_insert_involved" ON pedido_tracking;

-- Helper: devuelve true si el usuario actual está involucrado en el pedido
CREATE POLICY "pedido_tracking_select_involved" ON pedido_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM pedidos p
      WHERE p.id = pedido_id AND (
        p.cliente_id     = auth.uid() OR
        p.peragoger_id   = auth.uid() OR
        EXISTS (
          SELECT 1 FROM pedido_items pi
          WHERE pi.pedido_id = p.id AND pi.vendedor_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "pedido_tracking_insert_involved" ON pedido_tracking
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM pedidos p
      WHERE p.id = pedido_id AND (
        p.cliente_id     = auth.uid() OR
        p.peragoger_id   = auth.uid() OR
        EXISTS (
          SELECT 1 FROM pedido_items pi
          WHERE pi.pedido_id = p.id AND pi.vendedor_id = auth.uid()
        )
      )
    )
  );


-- ================================================================
-- 11. DIRECCIONES — Solo el dueño (usuario_id)
-- ================================================================
ALTER TABLE direcciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "direcciones_select_own" ON direcciones;
DROP POLICY IF EXISTS "direcciones_insert_own" ON direcciones;
DROP POLICY IF EXISTS "direcciones_update_own" ON direcciones;
DROP POLICY IF EXISTS "direcciones_delete_own" ON direcciones;

CREATE POLICY "direcciones_select_own" ON direcciones
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "direcciones_insert_own" ON direcciones
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "direcciones_update_own" ON direcciones
  FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "direcciones_delete_own" ON direcciones
  FOR DELETE USING (auth.uid() = usuario_id);


-- ================================================================
-- 12. CARRITO — Solo el dueño (usuario_id)
-- ================================================================
ALTER TABLE carrito ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "carrito_select_own" ON carrito;
DROP POLICY IF EXISTS "carrito_insert_own" ON carrito;
DROP POLICY IF EXISTS "carrito_update_own" ON carrito;
DROP POLICY IF EXISTS "carrito_delete_own" ON carrito;

CREATE POLICY "carrito_select_own" ON carrito
  FOR SELECT USING (auth.uid() = usuario_id);

CREATE POLICY "carrito_insert_own" ON carrito
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "carrito_update_own" ON carrito
  FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "carrito_delete_own" ON carrito
  FOR DELETE USING (auth.uid() = usuario_id);


-- ================================================================
-- 13. CALIFICACIONES — Lectura pública, solo el cliente_id puede crear/editar
-- ================================================================
ALTER TABLE calificaciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "calificaciones_public_read"    ON calificaciones;
DROP POLICY IF EXISTS "calificaciones_client_insert"  ON calificaciones;
DROP POLICY IF EXISTS "calificaciones_client_update"  ON calificaciones;

CREATE POLICY "calificaciones_public_read" ON calificaciones
  FOR SELECT USING (true);

CREATE POLICY "calificaciones_client_insert" ON calificaciones
  FOR INSERT WITH CHECK (auth.uid() = cliente_id);

CREATE POLICY "calificaciones_client_update" ON calificaciones
  FOR UPDATE USING (auth.uid() = cliente_id) WITH CHECK (auth.uid() = cliente_id);


-- ================================================================
-- 14. CALIFICACIONES_PRODUCTO — Lectura pública, solo el cliente_id crea
-- ================================================================
ALTER TABLE calificaciones_producto ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "calificaciones_producto_public_read"   ON calificaciones_producto;
DROP POLICY IF EXISTS "calificaciones_producto_client_insert" ON calificaciones_producto;

CREATE POLICY "calificaciones_producto_public_read" ON calificaciones_producto
  FOR SELECT USING (true);

CREATE POLICY "calificaciones_producto_client_insert" ON calificaciones_producto
  FOR INSERT WITH CHECK (auth.uid() = cliente_id);


-- ================================================================
-- STORAGE BUCKETS — Imágenes de productos y avatares
-- ================================================================

-- Asegurar que los buckets existen
INSERT INTO storage.buckets (id, name, public)
  VALUES ('productos', 'productos', true)
  ON CONFLICT (id) DO UPDATE SET public = true;

INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT (id) DO UPDATE SET public = true;

-- Limpiar policies anteriores de storage
DROP POLICY IF EXISTS "productos_bucket_public_read"   ON storage.objects;
DROP POLICY IF EXISTS "productos_bucket_vendor_upload" ON storage.objects;
DROP POLICY IF EXISTS "productos_bucket_vendor_delete" ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_public_read"     ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_auth_upload"     ON storage.objects;
DROP POLICY IF EXISTS "avatars_bucket_own_delete"      ON storage.objects;

-- BUCKET: productos
-- Lectura pública (imágenes se muestran en catálogo sin auth)
CREATE POLICY "productos_bucket_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'productos');

-- Solo agricultores/comerciantes pueden subir, bajo su carpeta uid/
CREATE POLICY "productos_bucket_vendor_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'productos' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text AND
    EXISTS (
      SELECT 1 FROM usuarios WHERE id = auth.uid() AND rol IN ('agricultor', 'comerciante')
    )
  );

-- Solo el propietario de la carpeta puede eliminar
CREATE POLICY "productos_bucket_vendor_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'productos' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- BUCKET: avatars
-- Lectura pública
CREATE POLICY "avatars_bucket_public_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

-- Cualquier usuario autenticado puede subir su propio avatar (carpeta uid/)
CREATE POLICY "avatars_bucket_auth_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Solo el dueño puede reemplazar/eliminar su avatar
CREATE POLICY "avatars_bucket_own_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "avatars_bucket_own_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );


-- ================================================================
-- VERIFICACIÓN — Ejecutar después para confirmar que todo está activo
-- ================================================================
-- SELECT schemaname, tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- ORDER BY tablename;
--
-- SELECT schemaname, tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;
-- ================================================================
