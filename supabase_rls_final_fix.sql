-- ================================================================
-- PERACO — RLS FINAL FIX
-- Problema: recursión infinita entre pedidos ↔ pedido_items
--   pedidos_vendor_select → pedido_items (con RLS)
--   pedido_items_client_select → pedidos (con RLS) → LOOP → 500
--
-- Solución: funciones SECURITY DEFINER que consultan sin RLS,
-- rompiendo el ciclo.
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Fecha: 2026-05-09
-- ================================================================


-- ================================================================
-- A. FUNCIONES HELPER (SECURITY DEFINER = sin RLS interno)
-- ================================================================

CREATE OR REPLACE FUNCTION public.fn_is_pedido_cliente(pedido_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pedidos
    WHERE id = pedido_uuid AND cliente_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_is_pedido_peragoger(pedido_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pedidos
    WHERE id = pedido_uuid AND peragoger_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_is_pedido_vendor(pedido_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.pedido_items
    WHERE pedido_id = pedido_uuid AND vendedor_id = auth.uid()
  );
$$;


-- ================================================================
-- B. ACTUALIZAR POLÍTICAS DE pedido_items
--    Usan las funciones helper → sin referencia circular
-- ================================================================

DROP POLICY IF EXISTS "pedido_items_client_select" ON public.pedido_items;
CREATE POLICY "pedido_items_client_select" ON public.pedido_items
  FOR SELECT USING (public.fn_is_pedido_cliente(pedido_id));

DROP POLICY IF EXISTS "pedido_items_client_insert" ON public.pedido_items;
CREATE POLICY "pedido_items_client_insert" ON public.pedido_items
  FOR INSERT WITH CHECK (public.fn_is_pedido_cliente(pedido_id));

DROP POLICY IF EXISTS "pedido_items_driver_select" ON public.pedido_items;
CREATE POLICY "pedido_items_driver_select" ON public.pedido_items
  FOR SELECT USING (public.fn_is_pedido_peragoger(pedido_id));


-- ================================================================
-- C. ACTUALIZAR POLÍTICAS DE pedidos
--    Vendedor usa fn_is_pedido_vendor → consulta pedido_items sin RLS
-- ================================================================

DROP POLICY IF EXISTS "pedidos_vendor_select" ON public.pedidos;
CREATE POLICY "pedidos_vendor_select" ON public.pedidos
  FOR SELECT USING (public.fn_is_pedido_vendor(id));

DROP POLICY IF EXISTS "pedidos_vendor_update" ON public.pedidos;
CREATE POLICY "pedidos_vendor_update" ON public.pedidos
  FOR UPDATE USING (public.fn_is_pedido_vendor(id));


-- ================================================================
-- D. ACTUALIZAR POLÍTICAS DE pedido_tracking
--    También tenía referencia circular indirecta
-- ================================================================

DROP POLICY IF EXISTS "pedido_tracking_select_involved" ON public.pedido_tracking;
CREATE POLICY "pedido_tracking_select_involved" ON public.pedido_tracking
  FOR SELECT USING (
    public.fn_is_pedido_cliente(pedido_id)
    OR public.fn_is_pedido_peragoger(pedido_id)
    OR public.fn_is_pedido_vendor(pedido_id)
  );


-- ================================================================
-- VERIFICACIÓN
-- ================================================================
-- SELECT proname, prosecdef FROM pg_proc
-- WHERE pronamespace = 'public'::regnamespace
--   AND proname LIKE 'fn_is_pedido%';
