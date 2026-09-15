CREATE TABLE IF NOT EXISTS supplier_reports (
  supplier_report_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scan_id uuid REFERENCES scans(scan_id) ON DELETE SET NULL,
  reporter_id uuid NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
  supplier_name text NOT NULL,
  supplier_contact text NOT NULL,
  delivery_date date,
  additional_details text,
  status text NOT NULL DEFAULT 'pending',
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz
);

ALTER TABLE supplier_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "supplier_reports_insert_own" ON supplier_reports;
CREATE POLICY "supplier_reports_insert_own"
  ON supplier_reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

DROP POLICY IF EXISTS "supplier_reports_select_own" ON supplier_reports;
CREATE POLICY "supplier_reports_select_own"
  ON supplier_reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);
