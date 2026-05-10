-- ================================================================
-- PERACO — SECURITY FIX v1.0
-- Corrige todas las alertas del Supabase Linter
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Fecha: 2026-04-27
-- ================================================================

-- ================================================================
-- A. HABILITAR RLS EN TABLAS QUE TENÍAN POLÍTICAS PERO RLS APAGADO
-- ================================================================

ALTER TABLE public.pedidos         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedido_items    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedido_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cultivos        ENABLE ROW LEVEL SECURITY;


-- ================================================================
-- B. POLÍTICAS RLS PARA TABLA cultivos (catálogo de referencia)
-- ================================================================
DROP POLICY IF EXISTS "cultivos_public_read" ON public.cultivos;

CREATE POLICY "cultivos_public_read" ON public.cultivos
  FOR SELECT USING (true);


-- ================================================================
-- C. ELIMINAR POLÍTICAS ANTIGUAS CON USING/CHECK (true) PERMISIVAS
-- ================================================================

-- calificaciones_producto: "Crear calificacion producto" tenía WITH CHECK (true)
DROP POLICY IF EXISTS "Crear calificacion producto"           ON public.calificaciones_producto;
DROP POLICY IF EXISTS "calificaciones_producto_client_insert" ON public.calificaciones_producto;

-- calificaciones_producto no tiene columna de usuario directa:
-- la identidad se verifica a través de calificaciones.cliente_id
CREATE POLICY "calificaciones_producto_client_insert" ON public.calificaciones_producto
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.calificaciones c
      WHERE c.id = calificacion_id
        AND c.cliente_id = auth.uid()
    )
  );


-- producto_imagenes: políticas "imagenes_*" con USING/CHECK (true)
DROP POLICY IF EXISTS "imagenes_delete" ON public.producto_imagenes;
DROP POLICY IF EXISTS "imagenes_insert" ON public.producto_imagenes;
DROP POLICY IF EXISTS "imagenes_update" ON public.producto_imagenes;

DROP POLICY IF EXISTS "producto_imagenes_public_read"   ON public.producto_imagenes;
DROP POLICY IF EXISTS "producto_imagenes_vendor_insert" ON public.producto_imagenes;
DROP POLICY IF EXISTS "producto_imagenes_vendor_update" ON public.producto_imagenes;
DROP POLICY IF EXISTS "producto_imagenes_vendor_delete" ON public.producto_imagenes;

CREATE POLICY "producto_imagenes_public_read" ON public.producto_imagenes
  FOR SELECT USING (true);

CREATE POLICY "producto_imagenes_vendor_insert" ON public.producto_imagenes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  );

CREATE POLICY "producto_imagenes_vendor_update" ON public.producto_imagenes
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  );

CREATE POLICY "producto_imagenes_vendor_delete" ON public.producto_imagenes
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.productos p
      WHERE p.id = producto_id AND p.vendedor_id = auth.uid()
    )
  );


-- ================================================================
-- D. FIJAR search_path EN FUNCIONES (previene search_path injection)
-- ================================================================
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT oid::regprocedure::text AS sig
    FROM pg_proc
    WHERE pronamespace = 'public'::regnamespace
      AND proname IN (
        'fn_actualizar_timestamp',
        'fn_generar_numero_pedido',
        'fn_reservar_inventario',
        'fn_tipo_usuario_actual',
        'fn_actualizar_estado_pedido_entrega',
        'fn_actualizar_estado_peragogher',
        'fn_actualizar_calificacion_peragogher',
        'generar_codigo_pedido',
        'actualizar_timestamp',
        '_gen_pedido_codigo'
      )
  LOOP
    EXECUTE format('ALTER FUNCTION %s SET search_path = public', r.sig);
  END LOOP;
END;
$$;


-- ================================================================
-- E. MOVER EXTENSIÓN pg_trgm A ESQUEMA extensions
-- ================================================================
-- Si falla porque el esquema 'extensions' no existe, créalo primero:
--   CREATE SCHEMA IF NOT EXISTS extensions;
ALTER EXTENSION pg_trgm SET SCHEMA extensions;


-- ================================================================
-- VERIFICACIÓN — Ejecutar después para confirmar
-- ================================================================
-- Tablas con RLS activo:
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE schemaname = 'public'
-- AND tablename IN ('pedidos','pedido_items','pedido_tracking','cultivos')
-- ORDER BY tablename;

-- Políticas activas:
-- SELECT tablename, policyname, cmd FROM pg_policies
-- WHERE schemaname = 'public'
-- AND tablename IN ('calificaciones_producto','producto_imagenes')
-- ORDER BY tablename, policyname;

-- Funciones con search_path fijo:
-- SELECT proname, proconfig FROM pg_proc
-- WHERE pronamespace = 'public'::regnamespace
-- AND proconfig IS NOT NULL;
