-- ============================================
-- SUPABASE DATABASE SCHEMA
-- Message App - Complete Schema
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_online ON users(is_online);

-- ============================================
-- 2. CONVERSATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS conversations (
  id TEXT PRIMARY KEY DEFAULT 'default',
  name TEXT DEFAULT 'Alliance Organization "v"',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default conversation
INSERT INTO conversations (id, name) 
VALUES ('default', 'Alliance Organization "v"')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 3. MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text TEXT,
  attachment_url TEXT,
  attachment_type TEXT, -- 'image', 'file', 'voice', 'gif'
  attachment_name TEXT,
  reply_to_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  is_forwarded BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_user ON messages(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_text_search ON messages USING gin(text gin_trgm_ops);

-- ============================================
-- 4. MESSAGE_REACTIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_reactions_message ON message_reactions(message_id);

-- ============================================
-- 5. MESSAGE_SEEN TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS message_seen (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seen_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_seen_message ON message_seen(message_id);
CREATE INDEX IF NOT EXISTS idx_seen_user ON message_seen(user_id);

-- ============================================
-- 6. TYPING_STATUS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS typing_status (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_typing_conversation ON typing_status(conversation_id);

-- ============================================
-- 7. TRIGGERS FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to tables
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_messages_updated_at ON messages;
CREATE TRIGGER update_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. VIEW: MESSAGES_ENRICHED
-- ============================================
-- This view includes user info and reaction counts
CREATE OR REPLACE VIEW messages_enriched AS
SELECT 
  m.id,
  m.conversation_id,
  m.user_id,
  m.text,
  m.attachment_url,
  m.attachment_type,
  m.attachment_name,
  m.reply_to_id,
  m.is_forwarded,
  m.is_deleted,
  m.created_at,
  m.updated_at,
  u.display_name as sender_name,
  u.photo_url as sender_photo,
  u.email as sender_email,
  (SELECT COUNT(*) FROM message_reactions WHERE message_id = m.id) as reaction_count,
  (SELECT COUNT(*) FROM message_seen WHERE message_id = m.id) as seen_count,
  (SELECT json_agg(json_build_object('emoji', emoji, 'count', count))
   FROM (
     SELECT emoji, COUNT(*) as count
     FROM message_reactions
     WHERE message_id = m.id
     GROUP BY emoji
   ) reactions
  ) as reactions
FROM messages m
LEFT JOIN users u ON m.user_id = u.id
WHERE m.is_deleted = false;

-- ============================================
-- 9. FUNCTION: SEARCH_MESSAGES
-- ============================================
CREATE OR REPLACE FUNCTION search_messages(
  search_query TEXT,
  conv_id TEXT DEFAULT 'default'
)
RETURNS TABLE (
  id UUID,
  conversation_id TEXT,
  user_id UUID,
  text TEXT,
  sender_name TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.conversation_id,
    m.user_id,
    m.text,
    u.display_name as sender_name,
    m.created_at
  FROM messages m
  LEFT JOIN users u ON m.user_id = u.id
  WHERE m.conversation_id = conv_id
    AND m.is_deleted = false
    AND m.text ILIKE '%' || search_query || '%'
  ORDER BY m.created_at DESC
  LIMIT 50;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 10. FUNCTION: GET_CONVERSATION_STATS
-- ============================================
CREATE OR REPLACE FUNCTION get_conversation_stats(conv_id TEXT DEFAULT 'default')
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_messages', COUNT(*),
    'total_users', COUNT(DISTINCT user_id),
    'latest_message_at', MAX(created_at)
  )
  INTO result
  FROM messages
  WHERE conversation_id = conv_id
    AND is_deleted = false;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_seen ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing_status ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view all users"
  ON users FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = id::text);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid()::text = id::text);

-- Conversations policies
CREATE POLICY "Anyone can view conversations"
  ON conversations FOR SELECT
  USING (true);

-- Messages policies
CREATE POLICY "Anyone authenticated can view messages"
  ON messages FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert messages"
  ON messages FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own messages"
  ON messages FOR UPDATE
  USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own messages"
  ON messages FOR DELETE
  USING (auth.uid()::text = user_id::text);

-- Reactions policies
CREATE POLICY "Anyone can view reactions"
  ON message_reactions FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can add reactions"
  ON message_reactions FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can remove own reactions"
  ON message_reactions FOR DELETE
  USING (auth.uid()::text = user_id::text);

-- Seen status policies
CREATE POLICY "Anyone can view seen status"
  ON message_seen FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can mark messages as seen"
  ON message_seen FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

-- Typing status policies
CREATE POLICY "Anyone can view typing status"
  ON typing_status FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own typing status"
  ON typing_status FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own typing status"
  ON typing_status FOR DELETE
  USING (auth.uid()::text = user_id::text);

-- ============================================
-- 12. REALTIME PUBLICATION
-- ============================================
-- Enable realtime for messages and typing status
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE typing_status;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Create storage buckets: chat_attachments, avatars
-- 3. Update Flutter code to use Supabase
-- ============================================
