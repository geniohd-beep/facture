async function run() {
  const ref = process.env.SUPABASE_PROJECT_REF || 'cklheguvwmxefilkcsjz';
  const key = process.env.SUPABASE_SERVICE_KEY;

  const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: `ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;`
    })
  });

  console.log('Status:', res.status);
  const text = await res.text();
  console.log('Response:', text);
}

run().catch(e => console.error(e.message));
