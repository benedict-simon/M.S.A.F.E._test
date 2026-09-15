ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS store_description text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS store_hours text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS store_categories text[];
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS supplier_name text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS supplier_contact text;

NOTIFY pgrst, 'reload schema';
