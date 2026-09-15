-- Only the backend's service_role key touches this table — RLS is enabled with zero policies,
-- so the anon/authenticated roles the mobile app uses get no access at all, even by accident.

CREATE TABLE IF NOT EXISTS pending_signups (
  email text PRIMARY KEY,
  otp_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  attempts int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE pending_signups ENABLE ROW LEVEL SECURITY;

-- Sweeps abandoned/expired signup attempts so this table doesn't grow forever.
CREATE OR REPLACE FUNCTION delete_expired_pending_signups()
RETURNS void AS $$
BEGIN
  DELETE FROM pending_signups WHERE expires_at <= now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'delete-expired-pending-signups';

SELECT cron.schedule(
  'delete-expired-pending-signups',
  '0 * * * *', -- hourly
  $$SELECT delete_expired_pending_signups()$$
);
