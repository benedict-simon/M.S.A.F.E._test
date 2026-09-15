ALTER TABLE profiles ADD COLUMN IF NOT EXISTS account_type text NOT NULL DEFAULT 'consumer';

CREATE TABLE IF NOT EXISTS vendor_applications (
  vendor_application_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES profiles(profile_id) ON DELETE CASCADE,
  business_name text NOT NULL,
  contact_number text NOT NULL,
  stall_lat double precision,
  stall_lng double precision,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason text,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz
);

ALTER TABLE vendor_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vendor_applications_insert_own" ON vendor_applications;
CREATE POLICY "vendor_applications_insert_own"
  ON vendor_applications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

DROP POLICY IF EXISTS "vendor_applications_select_own" ON vendor_applications;
CREATE POLICY "vendor_applications_select_own"
  ON vendor_applications FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

CREATE OR REPLACE FUNCTION sync_profile_account_type_from_vendor_application()
RETURNS trigger AS $$
BEGIN
  IF NEW.status = 'approved' THEN
    UPDATE profiles SET account_type = 'vendor' WHERE profile_id = NEW.profile_id;
  ELSE
    UPDATE profiles SET account_type = 'consumer' WHERE profile_id = NEW.profile_id;
  END IF;

  NEW.reviewed_at = CASE WHEN NEW.status = 'pending' THEN NULL ELSE now() END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS vendor_application_status_sync ON vendor_applications;
CREATE TRIGGER vendor_application_status_sync
  BEFORE UPDATE ON vendor_applications
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION sync_profile_account_type_from_vendor_application();

DROP TRIGGER IF EXISTS vendor_application_status_sync_insert ON vendor_applications;
CREATE TRIGGER vendor_application_status_sync_insert
  BEFORE INSERT ON vendor_applications
  FOR EACH ROW
  EXECUTE FUNCTION sync_profile_account_type_from_vendor_application();
