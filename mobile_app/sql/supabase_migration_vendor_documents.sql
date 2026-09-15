ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS valid_id_path text;
ALTER TABLE vendor_applications ADD COLUMN IF NOT EXISTS vendor_permit_path text;

INSERT INTO storage.buckets (id, name, public)
VALUES ('vendor-documents', 'vendor-documents', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "vendor_documents_insert_own" ON storage.objects;
CREATE POLICY "vendor_documents_insert_own"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'vendor-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "vendor_documents_select_own" ON storage.objects;
CREATE POLICY "vendor_documents_select_own"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'vendor-documents' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "vendor_documents_update_own" ON storage.objects;
CREATE POLICY "vendor_documents_update_own"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'vendor-documents' AND (storage.foldername(name))[1] = auth.uid()::text);
