const { createClient } = require('@supabase/supabase-js');
const ws = require('ws');

const supabaseUrl = process.env.SUPABASE_URL || 'https://cklheguvwmxefilkcsjz.supabase.co';
const serviceRoleKey = process.env.SUPABASE_SERVICE_KEY;

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  realtime: { transport: ws }
});

async function run() {
  // Get the auth header being used
  const headers = supabase.restHeaders();
  console.log('Headers:', JSON.stringify(headers, null, 2));

  const { data, error } = await supabase
    .from('products')
    .insert({ code: 'ROLE001', name: 'SERVICE ROLE TEST', sale_price: 10, stock: 1 })
    .select();

  if (error) {
    console.error('Insert error:', error.message, JSON.stringify(error));
    return;
  }
  console.log('Insert succeeded:', JSON.stringify(data, null, 2));
}

run();
