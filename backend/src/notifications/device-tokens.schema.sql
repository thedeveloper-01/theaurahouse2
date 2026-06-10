-- Device Token Management Schema
-- Handles registration, rotation, and deletion of FCM device tokens

CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_id VARCHAR(255), -- Optional: device identifier for deduplication
  app_version VARCHAR(50), -- Optional: app version for debugging
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  last_used_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Unique constraint: one active token per user+device combination
  UNIQUE (user_id, device_id, platform) WHERE is_active = TRUE,
  
  -- Index for fast lookups
  INDEX idx_device_tokens_user_id (user_id),
  INDEX idx_device_tokens_token (token),
  INDEX idx_device_tokens_active (user_id, is_active) WHERE is_active = TRUE
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_device_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  NEW.last_used_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update timestamps
CREATE TRIGGER device_tokens_updated_at
  BEFORE UPDATE ON device_tokens
  FOR EACH ROW
  EXECUTE FUNCTION update_device_tokens_updated_at();

-- Deduplication Rules:
-- 1. If same user_id + device_id + platform exists and is_active, update token
-- 2. If same token exists for different user, mark old one as inactive
-- 3. If same user_id + token exists, update last_used_at
-- 4. Maximum 10 active tokens per user (cleanup old ones)

-- Function to register/update device token with deduplication
CREATE OR REPLACE FUNCTION register_device_token(
  p_user_id UUID,
  p_token TEXT,
  p_platform VARCHAR(20),
  p_device_id VARCHAR(255) DEFAULT NULL,
  p_app_version VARCHAR(50) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_token_id UUID;
  v_existing_token_id UUID;
  v_active_count INTEGER;
BEGIN
  -- Rule 1: Check if same user_id + device_id + platform exists
  IF p_device_id IS NOT NULL THEN
    SELECT id INTO v_existing_token_id
    FROM device_tokens
    WHERE user_id = p_user_id
      AND device_id = p_device_id
      AND platform = p_platform
      AND is_active = TRUE
    LIMIT 1;
    
    IF v_existing_token_id IS NOT NULL THEN
      -- Update existing token
      UPDATE device_tokens
      SET token = p_token,
          app_version = COALESCE(p_app_version, app_version),
          last_used_at = now(),
          is_active = TRUE
      WHERE id = v_existing_token_id;
      RETURN v_existing_token_id;
    END IF;
  END IF;
  
  -- Rule 2: If same token exists for different user, mark old one as inactive
  UPDATE device_tokens
  SET is_active = FALSE
  WHERE token = p_token
    AND user_id != p_user_id
    AND is_active = TRUE;
  
  -- Rule 3: Check if same user_id + token exists
  SELECT id INTO v_existing_token_id
  FROM device_tokens
  WHERE user_id = p_user_id
    AND token = p_token
  LIMIT 1;
  
  IF v_existing_token_id IS NOT NULL THEN
    -- Update existing token
    UPDATE device_tokens
    SET platform = p_platform,
        device_id = COALESCE(p_device_id, device_id),
        app_version = COALESCE(p_app_version, app_version),
        last_used_at = now(),
        is_active = TRUE
    WHERE id = v_existing_token_id;
    RETURN v_existing_token_id;
  END IF;
  
  -- Rule 4: Check active token count and deactivate oldest if > 10
  SELECT COUNT(*) INTO v_active_count
  FROM device_tokens
  WHERE user_id = p_user_id
    AND is_active = TRUE;
  
  IF v_active_count >= 10 THEN
    -- Deactivate oldest token
    UPDATE device_tokens
    SET is_active = FALSE
    WHERE id = (
      SELECT id
      FROM device_tokens
      WHERE user_id = p_user_id
        AND is_active = TRUE
      ORDER BY last_used_at ASC
      LIMIT 1
    );
  END IF;
  
  -- Insert new token
  INSERT INTO device_tokens (user_id, token, platform, device_id, app_version)
  VALUES (p_user_id, p_token, p_platform, p_device_id, p_app_version)
  RETURNING id INTO v_token_id;
  
  RETURN v_token_id;
END;
$$ LANGUAGE plpgsql;

-- Function to delete device token (on logout)
CREATE OR REPLACE FUNCTION delete_device_token(
  p_user_id UUID,
  p_token TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE device_tokens
  SET is_active = FALSE
  WHERE user_id = p_user_id
    AND token = p_token
    AND is_active = TRUE;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to get all active tokens for a user
CREATE OR REPLACE FUNCTION get_user_device_tokens(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  token TEXT,
  platform VARCHAR(20),
  device_id VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE,
  last_used_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT dt.id, dt.token, dt.platform, dt.device_id, dt.created_at, dt.last_used_at
  FROM device_tokens dt
  WHERE dt.user_id = p_user_id
    AND dt.is_active = TRUE
  ORDER BY dt.last_used_at DESC;
END;
$$ LANGUAGE plpgsql;

