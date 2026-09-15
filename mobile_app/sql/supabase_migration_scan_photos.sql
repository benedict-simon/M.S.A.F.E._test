ALTER TABLE scans ADD COLUMN IF NOT EXISTS image_path text;

INSERT INTO storage.buckets (id, name, public)
VALUES ('scan-photos', 'scan-photos', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "scan_photos_insert_own" ON storage.objects;
CREATE POLICY "scan_photos_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'scan-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "scan_photos_select_own" ON storage.objects;
CREATE POLICY "scan_photos_select_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'scan-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
