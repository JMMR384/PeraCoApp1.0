-- ================================================================
-- PERACO — RLS PEDIDOS FIX
-- Crea las políticas que faltaban después de habilitar RLS en:
--   pedidos, pedido_items, pedido_tracking
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Fecha: 2026-05-09
-- ================================================================


-- ================================================================
-- A. POLÍTICAS PARA pedido_items
-- ================================================================

-- Vendedor ve y gestiona sus propios items
DROP POLICY IF EXISTS "pedido_items_vendor_select" ON public.pedido_items;
CREATE POLICY "pedido_items_vendor_select" ON public.pedido_items
  FOR SELECT USING (vendedor_id = auth.uid());

-- Cliente ve los items de sus pedidos
DROP POLICY IF EXISTS "pedido_items_client_select" ON public.pedido_items;
CREATE POLICY "pedido_items_client_select" ON public.pedido_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedidos p
      WHERE p.id = pedido_id AND p.cliente_id = auth.uid()
    )
  );

-- Cliente inserta items al crear pedido
DROP POLICY IF EXISTS "pedido_items_client_insert" ON public.pedido_items;
CREATE POLICY "pedido_items_client_insert" ON public.pedido_items
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pedidos p
      WHERE p.id = pedido_id AND p.cliente_id = auth.uid()
    )
  );


-- ================================================================
-- B. POLÍTICAS PARA pedidos
-- ================================================================

-- Cliente gestiona sus propios pedidos
DROP POLICY IF EXISTS "pedidos_client_select" ON public.pedidos;
CREATE POLICY "pedidos_client_select" ON public.pedidos
  FOR SELECT USING (cliente_id = auth.uid());

DROP POLICY IF EXISTS "pedidos_client_insert" ON public.pedidos;
CREATE POLICY "pedidos_client_insert" ON public.pedidos
  FOR INSERT WITH CHECK (cliente_id = auth.uid());

DROP POLICY IF EXISTS "pedidos_client_update" ON public.pedidos;
CREATE POLICY "pedidos_client_update" ON public.pedidos
  FOR UPDATE USING (cliente_id = auth.uid());

-- Vendedor ve pedidos donde tiene items
DROP POLICY IF EXISTS "pedidos_vendor_select" ON public.pedidos;
CREATE POLICY "pedidos_vendor_select" ON public.pedidos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = id AND pi.vendedor_id = auth.uid()
    )
  );

-- Vendedor actualiza estado del pedido (preparando, listo)
DROP POLICY IF EXISTS "pedidos_vendor_update" ON public.pedidos;
CREATE POLICY "pedidos_vendor_update" ON public.pedidos
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = id AND pi.vendedor_id = auth.uid()
    )
  );


-- ================================================================
-- C. POLÍTICAS PARA pedido_tracking
-- ================================================================

-- Cliente ve el tracking de sus pedidos
DROP POLICY IF EXISTS "pedido_tracking_client_select" ON public.pedido_tracking;
CREATE POLICY "pedido_tracking_client_select" ON public.pedido_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedidos p
      WHERE p.id = pedido_id AND p.cliente_id = auth.uid()
    )
  );

-- Vendedor ve el tracking de sus pedidos
DROP POLICY IF EXISTS "pedido_tracking_vendor_select" ON public.pedido_tracking;
CREATE POLICY "pedido_tracking_vendor_select" ON public.pedido_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = pedido_id AND pi.vendedor_id = auth.uid()
    )
  );

-- Vendedor inserta registros de tracking al cambiar estado
DROP POLICY IF EXISTS "pedido_tracking_vendor_insert" ON public.pedido_tracking;
CREATE POLICY "pedido_tracking_vendor_insert" ON public.pedido_tracking
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = pedido_id AND pi.vendedor_id = auth.uid()
    )
  );


-- ================================================================
-- VERIFICACIÓN — Ejecutar después para confirmar políticas creadas
-- ================================================================
-- SELECT tablename, policyname, cmd, qual
-- FROM pg_policies
-- WHERE schemaname = 'public'
--   AND tablename IN ('pedidos', 'pedido_items', 'pedido_tracking')
-- ORDER BY tablename, policyname;
