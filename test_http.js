const key = process.env.SUPABASE_SERVICE_KEY;
const url = process.env.SUPABASE_URL || 'https://cklheguvwmxefilkcsjz.supabase.co';
const body = { code: 'ROLETEST2', name: 'Direct HTTP test', sale_price: 10, stock: 5 };

async function run() {
  const res = await fetch(`${url}/rest/v1/products`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'apikey': key,
      'Authorization': `Bearer ${key}`,
      'Prefer': 'return=representation'
    },
    body: JSON.stringify(body)
  });

  console.log('Status:', res.status);
  const text = await res.text();
  console.log('Response:', text);
}

run().catch(e => console.error(e.message));
