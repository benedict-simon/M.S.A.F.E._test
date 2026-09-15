ALTER TABLE notifications ADD COLUMN IF NOT EXISTS feedback_id uuid REFERENCES user_feedback(feedback_id) ON DELETE SET NULL;

CREATE OR REPLACE FUNCTION notify_feedback_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.admin_response IS NOT NULL
     AND NEW.admin_response IS DISTINCT FROM OLD.admin_response THEN
    INSERT INTO notifications (profile_id, title, body, type, feedback_id)
    VALUES (
      NEW.user_id,
      'We replied to your feedback',
      CASE
        WHEN length(NEW.admin_response) > 140 THEN left(NEW.admin_response, 140) || '...'
        ELSE NEW.admin_response
      END,
      'feedbackResponded',
      NEW.feedback_id
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_feedback_response ON user_feedback;
CREATE TRIGGER trg_notify_feedback_response
AFTER UPDATE ON user_feedback
FOR EACH ROW
EXECUTE FUNCTION notify_feedback_response();
