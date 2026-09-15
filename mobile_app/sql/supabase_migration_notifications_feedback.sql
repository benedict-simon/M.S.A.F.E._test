ALTER TABLE notifications ALTER COLUMN broadcast_id DROP NOT NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS scan_id uuid REFERENCES scans(scan_id) ON DELETE SET NULL;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS report_id uuid REFERENCES reports(report_id) ON DELETE SET NULL;

-- 2. Lock notifications down to their own profile.
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
CREATE POLICY "notifications_select_own"
  ON notifications FOR SELECT
  TO authenticated
  USING (auth.uid() = profile_id);

DROP POLICY IF EXISTS "notifications_insert_own" ON notifications;
CREATE POLICY "notifications_insert_own"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = profile_id);

DROP POLICY IF EXISTS "notifications_update_own" ON notifications;
CREATE POLICY "notifications_update_own"
  ON notifications FOR UPDATE
  TO authenticated
  USING (auth.uid() = profile_id)
  WITH CHECK (auth.uid() = profile_id);


ALTER TABLE user_feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "user_feedback_insert_own" ON user_feedback;
CREATE POLICY "user_feedback_insert_own"
  ON user_feedback FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "user_feedback_select_own" ON user_feedback;
CREATE POLICY "user_feedback_select_own"
  ON user_feedback FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
