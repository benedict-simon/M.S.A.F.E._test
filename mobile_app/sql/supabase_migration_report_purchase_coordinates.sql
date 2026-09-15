ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_lat double precision;
ALTER TABLE reports ADD COLUMN IF NOT EXISTS purchase_lng double precision;

NOTIFY pgrst, 'reload schema';
