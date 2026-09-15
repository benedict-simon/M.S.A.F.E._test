ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS stall_number text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS supplier_address text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS supplier_accreditation_no text;

NOTIFY pgrst, 'reload schema';
