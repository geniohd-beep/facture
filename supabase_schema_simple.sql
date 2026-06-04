CREATE TABLE IF NOT EXISTS public.companies (
  local_id INTEGER UNIQUE,
  ruc TEXT NOT NULL,
  business_name TEXT NOT NULL,
  trade_name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  logo_path TEXT DEFAULT '',
  is_active INTEGER DEFAULT 1,
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.customers (
  local_id INTEGER UNIQUE,
  document_type TEXT NOT NULL,
  document_number TEXT NOT NULL,
  first_name TEXT DEFAULT '',
  last_name TEXT DEFAULT '',
  full_name TEXT DEFAULT '',
  address TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  email TEXT DEFAULT '',
  from_api INTEGER DEFAULT 0,
  created_at TEXT DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.products (
  local_id INTEGER UNIQUE,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  category TEXT DEFAULT '',
  purchase_price REAL DEFAULT 0,
  sale_price REAL DEFAULT 0,
  stock INTEGER DEFAULT 0,
  unit_type TEXT DEFAULT 'UNIDAD',
  is_active INTEGER DEFAULT 1,
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.documents (
  local_id INTEGER UNIQUE,
  company_id INTEGER NOT NULL,
  customer_id INTEGER,
  document_type TEXT NOT NULL,
  series TEXT NOT NULL,
  number INTEGER NOT NULL,
  customer_doc_type TEXT NOT NULL,
  customer_doc_number TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_address TEXT DEFAULT '',
  customer_phone TEXT DEFAULT '',
  customer_email TEXT DEFAULT '',
  sent_whatsapp INTEGER DEFAULT 0,
  sent_email INTEGER DEFAULT 0,
  issue_date TEXT NOT NULL,
  subtotal REAL DEFAULT 0,
  igv REAL DEFAULT 0,
  total REAL DEFAULT 0,
  payment_method TEXT DEFAULT 'Efectivo',
  payment_status TEXT DEFAULT 'TOTAL',
  status TEXT DEFAULT 'EMITIDO',
  sunat_ticket TEXT,
  sunat_cdr TEXT,
  notes TEXT,
  tax_regime TEXT DEFAULT 'GENERAL',
  delivery_date TEXT,
  delivery_address TEXT DEFAULT '',
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.document_items (
  local_id INTEGER UNIQUE,
  document_id INTEGER NOT NULL,
  product_id INTEGER NOT NULL,
  product_code TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity REAL NOT NULL,
  unit_type TEXT DEFAULT 'UNIDAD',
  unit_price REAL NOT NULL,
  subtotal REAL NOT NULL,
  igv REAL NOT NULL,
  total REAL NOT NULL,
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.document_series (
  local_id INTEGER UNIQUE,
  company_id INTEGER NOT NULL,
  document_type TEXT NOT NULL,
  series TEXT NOT NULL,
  current_number INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  device_id TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.companies DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_series DISABLE ROW LEVEL SECURITY;

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
