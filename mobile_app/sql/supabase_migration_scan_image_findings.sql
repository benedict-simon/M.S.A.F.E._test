ALTER TABLE scans ADD COLUMN IF NOT EXISTS hue_deg real;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS saturation_pct real;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS brightness_pct real;
ALTER TABLE scans ADD COLUMN IF NOT EXISTS uniformity_pct real;
