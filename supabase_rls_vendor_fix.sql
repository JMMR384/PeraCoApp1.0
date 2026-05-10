-- Fix pedidos_vendor_select y pedidos_vendor_update
-- El problema: 'id' sin calificar dentro del subquery fue interpretado
-- como pedido_items.id en vez de pedidos.id. Se debe usar 'pedidos.id'.

DROP POLICY IF EXISTS "pedidos_vendor_select" ON public.pedidos;
CREATE POLICY "pedidos_vendor_select" ON public.pedidos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = pedidos.id
        AND pi.vendedor_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "pedidos_vendor_update" ON public.pedidos;
CREATE POLICY "pedidos_vendor_update" ON public.pedidos
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.pedido_items pi
      WHERE pi.pedido_id = pedidos.id
        AND pi.vendedor_id = auth.uid()
    )
  );
