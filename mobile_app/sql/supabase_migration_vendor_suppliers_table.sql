CREATE TABLE IF NOT EXISTS vendor_suppliers (
  vendor_supplier_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_application_id uuid NOT NULL REFERENCES vendor_applications(vendor_application_id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
  supplier_name text NOT NULL,
  supplier_contact text,
  supplier_address text,
  supplier_house_number text,
  supplier_street text,
  supplier_barangay text,
  supplier_city text,
  supplier_province text,
  supplier_postal_code text,
  supplier_country text,
  supplier_lat double precision,
  supplier_lng double precision,
  supplier_accreditation_no text,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_house_number text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_street text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_barangay text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_city text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_province text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_postal_code text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_country text;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_lat double precision;
ALTER TABLE vendor_suppliers ADD COLUMN IF NOT EXISTS supplier_lng double precision;

ALTER TABLE vendor_suppliers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendor_suppliers_select_own" ON vendor_suppliers;
CREATE POLICY "vendor_suppliers_select_own"
  ON vendor_suppliers FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "vendor_suppliers_insert_own" ON vendor_suppliers;
CREATE POLICY "vendor_suppliers_insert_own"
  ON vendor_suppliers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

DROP POLICY IF EXISTS "vendor_suppliers_update_own" ON vendor_suppliers;
CREATE POLICY "vendor_suppliers_update_own"
  ON vendor_suppliers FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);

DROP POLICY IF EXISTS "vendor_suppliers_delete_own" ON vendor_suppliers;
CREATE POLICY "vendor_suppliers_delete_own"
  ON vendor_suppliers FOR DELETE
  TO authenticated
  USING (auth.uid() = profile_id);

-- Carry over any single-supplier data already saved under the old columns,
-- as each vendor's first entry in the new table, before those columns go away.
-- Guarded so this file is safe to re-run even after a previous run already
-- dropped these columns from vendor_applications.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'vendor_applications' AND column_name = 'supplier_name'
  ) THEN
    INSERT INTO vendor_suppliers (vendor_application_id, profile_id, supplier_name, supplier_contact, supplier_address, supplier_accreditation_no)
    SELECT vendor_application_id, profile_id, supplier_name, supplier_contact, supplier_address, supplier_accreditation_no
    FROM vendor_applications
    WHERE supplier_name IS NOT NULL AND trim(supplier_name) <> '';
  END IF;
END $$;

ALTER TABLE vendor_applications DROP COLUMN IF EXISTS supplier_name;
ALTER TABLE vendor_applications DROP COLUMN IF EXISTS supplier_contact;
ALTER TABLE vendor_applications DROP COLUMN IF EXISTS supplier_address;
ALTER TABLE vendor_applications DROP COLUMN IF EXISTS supplier_accreditation_no;

NOTIFY pgrst, 'reload schema';
