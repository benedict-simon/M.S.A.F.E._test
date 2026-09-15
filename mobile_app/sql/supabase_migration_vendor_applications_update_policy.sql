DROP POLICY IF EXISTS "vendor_applications_update_own" ON vendor_applications;
CREATE POLICY "vendor_applications_update_own"
  ON vendor_applications FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);
