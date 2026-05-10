-- ================================================================
-- PERACO — SCHEMA ADDITIONS v1.1
-- Nuevas columnas y tablas para funcionalidades de cosecha→producto y OTA updates
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- Fecha: 2026-04-27
-- ================================================================

-- ================================================================
-- A. VINCULAR COSECHAS A PRODUCTOS
--    Permite detectar si ya existe un producto publicado para una cosecha
-- ================================================================
ALTER TABLE public.productos
  ADD COLUMN IF NOT EXISTS cosecha_id uuid
  REFERENCES public.cosechas_programadas(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_productos_cosecha_id
  ON public.productos(cosecha_id)
  WHERE cosecha_id IS NOT NULL;


-- ================================================================
-- B. TABLA app_versions — Gestión de versiones para OTA updates
-- ================================================================
CREATE TABLE IF NOT EXISTS public.app_versions (
  id            uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  platform      text        NOT NULL CHECK (platform IN ('android', 'ios')),
  version       text        NOT NULL,       -- Ej: "1.1.0"
  build_number  integer     NOT NULL,       -- Incremental, mayor = más nuevo
  download_url  text        NOT NULL,       -- URL pública del APK/IPA
  changelog_es  text,                       -- Novedades en español
  force_update  boolean     DEFAULT false  NOT NULL,
  activo        boolean     DEFAULT true   NOT NULL,
  created_at    timestamptz DEFAULT now()  NOT NULL,
  UNIQUE (platform, build_number)
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_versions_public_read" ON public.app_versions;
CREATE POLICY "app_versions_public_read" ON public.app_versions
  FOR SELECT USING (activo = true);

-- Versión inicial — actualizar download_url con el APK real
INSERT INTO public.app_versions (platform, version, build_number, download_url, changelog_es)
VALUES (
  'android',
  '1.0.0',
  1,
  'https://tu-servidor.com/peraco-v1.0.0.apk',
  'Versión inicial de PeraCo. Marketplace agrícola colombiano.'
) ON CONFLICT (platform, build_number) DO NOTHING;
