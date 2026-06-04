import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabase = createClient(
  'https://cklheguvwmxefilkcsjz.supabase.co',
  'sb_publishable_Hi8zMJt2EhQEO3LRa5eoEA_pp7L__q1'
);

const product = {
  local_id: 1,
  code: 'MIEL1KG',
  name: 'MIEL DE 1 KILO',
  description: '',
  category: 'ABARROTES',
  purchase_price: 50,
  sale_price: 85,
  stock: 100,
  unit_type: 'UNIDAD',
  is_active: 1,
  device_id: 'admin',
  updated_at: new Date().toISOString()
};

const { data, error } = await supabase.from('products').insert(product).select();
if (error) {
  console.error('❌ Error:', error.message);
} else {
  console.log('✅ Producto insertado:', data[0].code, '- S/.', data[0].sale_price, '- Stock:', data[0].stock);
}
