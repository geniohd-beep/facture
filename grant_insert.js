const { Client } = require('pg');

// Try different pooler formats
const configs = [
  // Format 1: postgres.project-ref@pooler
  { host: 'aws-0-us-west-1.pooler.supabase.com', port: 6543, user: 'postgres.cklheguvwmxefilkcsjz', password: 'F@cture.123', database: 'postgres' },
  // Format 2: same but port 5432
  { host: 'aws-0-us-west-1.pooler.supabase.com', port: 5432, user: 'postgres.cklheguvwmxefilkcsjz', password: 'F@cture.123', database: 'postgres' },
  // Format 3: postgres as user, project-ref in db
  { host: 'aws-0-us-west-1.pooler.supabase.com', port: 6543, user: 'postgres', password: 'F@cture.123', database: 'postgres' },
  // Format 4: project-ref as user
  { host: 'aws-0-us-west-1.pooler.supabase.com', port: 6543, user: 'cklheguvwmxefilkcsjz', password: 'F@cture.123', database: 'postgres' },
];

async function tryConnect(cfg) {
  const client = new Client({ ...cfg, ssl: { rejectUnauthorized: false } });
  await client.connect();
  const res = await client.query('SELECT current_user, version()');
  console.log(`Connected! user=${res.rows[0].current_user}`);
  await client.end();
  return true;
}

async function run() {
  for (const cfg of configs) {
    try {
      console.log(`Trying: user=${cfg.user} host=${cfg.host}:${cfg.port} db=${cfg.database}`);
      await tryConnect(cfg);
      return;
    } catch (e) {
      console.log(`  Failed: ${e.message}`);
    }
  }
}

run().catch(e => console.error('All failed:', e.message));
