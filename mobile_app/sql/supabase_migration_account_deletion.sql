ALTER TABLE profiles ADD COLUMN IF NOT EXISTS deletion_requested_at timestamptz;

CREATE OR REPLACE FUNCTION delete_overdue_accounts()
RETURNS void AS $$
BEGIN
  DELETE FROM auth.users
  WHERE id IN (
    SELECT profile_id FROM profiles
    WHERE deletion_requested_at IS NOT NULL
      AND deletion_requested_at <= now() - interval '30 days'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA extensions;

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'delete-overdue-accounts';

SELECT cron.schedule(
  'delete-overdue-accounts',
  '0 3 * * *', -- daily at 03:00 UTC
  $$SELECT delete_overdue_accounts()$$
);
