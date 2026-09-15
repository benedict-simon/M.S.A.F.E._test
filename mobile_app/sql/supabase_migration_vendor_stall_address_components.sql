ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_house_number text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_street text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_barangay text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_city text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_province text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_postal_code text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_country text;
