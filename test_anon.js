const { createClient } = require('@supabase/supabase-js');
const ws = require('ws');

const supabaseUrl = 'https://cklheguvwmxefilkcsjz.supabase.co';
const anonKey = 'sb_publishable_Hi8zMJt2EhQEO3LRa5eoEA_pp7L__q1';

const supabase = createClient(supabaseUrl, anonKey, {
  realtime: { transport: ws }
});

async function run() {
  const { data, error } = await supabase
    .from('products')
    .insert({ code: 'ANON001', name: 'ANON TEST AFTER FIX', sale_price: 10, stock: 1 })
    .select();

  if (error) {
    console.error('Anon insert error:', error.message);
    return;
  }
  console.log('Anon insert succeeded!');
  console.log(JSON.stringify(data, null, 2));
}

run();
