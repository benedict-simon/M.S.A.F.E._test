ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_house_number text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_street text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_barangay text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_city text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_province text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_postal_code text;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_country text;
