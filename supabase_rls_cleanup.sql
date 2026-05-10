-- ================================================================
-- PERACO — RLS CLEANUP
-- Elimina políticas inseguras, duplicadas y con bugs.
-- Deja un set limpio y correcto por rol.
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Fecha: 2026-05-09
-- ================================================================


-- ================================================================
-- A. LIMPIAR pedidos
-- ================================================================

-- Inseguras (USING true)
DROP POLICY IF EXISTS "pedidos_select"           ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_update"           ON public.pedidos;

-- Duplicadas/antiguas
DROP POLICY IF EXISTS "pedidos_insert"           ON public.pedidos;
DROP POLICY IF EXISTS "Cliente crea pedidos"     ON public.pedidos;
DROP POLICY IF EXISTS "Cliente ve sus pedidos"   ON public.pedidos;
DROP POLICY IF EXISTS "Peragoger ve sus entregas" ON public.pedidos;
DROP POLICY IF EXISTS "Actualizar pedidos"       ON public.pedidos;

-- Buggy (pi.pedido_id = pi.id en vez de pi.pedido_id = id)
DROP POLICY IF EXISTS "pedidos_vendor_select"    ON public.pedidos;
DROP POLICY IF EXISTS "pedidos_vendor_update"    ON public.pedidos;

-- Recrear vendor con join correcto
CREATE POLICY "pedidos_vendor_select" ON public.pedidos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = id
        AND pi.vendedor_id = auth.uid()
    )
  );

CREATE POLICY "pedidos_vendor_update" ON public.pedidos
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = id
        AND pi.vendedor_id = auth.uid()
    )
  );

-- (pedidos_client_select/insert/update, pedidos_driver_select/update se quedan igual)


-- ================================================================
-- B. LIMPIAR pedido_items
-- ================================================================

-- Insegura (USING true)
DROP POLICY IF EXISTS "items_select"             ON public.pedido_items;

-- Duplicadas/antiguas
DROP POLICY IF EXISTS "items_insert"             ON public.pedido_items;
DROP POLICY IF EXISTS "Crear items"              ON public.pedido_items;
DROP POLICY IF EXISTS "Ver items de mis pedidos" ON public.pedido_items;

-- (pedido_items_vendor_select, pedido_items_client_select/insert,
--  pedido_items_driver_select se quedan igual)


-- ================================================================
-- C. LIMPIAR pedido_tracking
-- ================================================================

-- Buggy (pi.pedido_id = pi.pedido_id — siempre true)
DROP POLICY IF EXISTS "pedido_tracking_vendor_select" ON public.pedido_tracking;

-- Duplicadas
DROP POLICY IF EXISTS "pedido_tracking_vendor_insert" ON public.pedido_tracking;
DROP POLICY IF EXISTS "pedido_tracking_client_select" ON public.pedido_tracking;
DROP POLICY IF EXISTS "Ver tracking de mis pedidos"   ON public.pedido_tracking;
DROP POLICY IF EXISTS "Crear tracking"                ON public.pedido_tracking;

-- (Todos ven tracking: true, Todos crean tracking,
--  pedido_tracking_select_involved, pedido_tracking_insert_involved se quedan)


-- ================================================================
-- VERIFICACIÓN FINAL
-- ================================================================
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename IN ('pedidos', 'pedido_items', 'pedido_tracking')
-- ORDER BY tablename, policyname;
