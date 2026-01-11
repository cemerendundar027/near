-- ============================================================================
-- NEAR APP - SUPABASE DATABASE SCHEMA
-- ============================================================================
-- PART 1: Önce tüm tabloları oluştur
-- PART 2: Sonra policy'leri ekle
-- ============================================================================

-- ============================================================================
-- PART 1: TABLOLAR
-- ============================================================================

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  phone TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ DEFAULT now(),
  -- Privacy settings (2.6)
  privacy_last_seen TEXT DEFAULT 'everyone' CHECK (privacy_last_seen IN ('everyone', 'contacts', 'nobody')),
  privacy_profile_photo TEXT DEFAULT 'everyone' CHECK (privacy_profile_photo IN ('everyone', 'contacts', 'nobody')),
  privacy_about TEXT DEFAULT 'everyone' CHECK (privacy_about IN ('everyone', 'contacts', 'nobody')),
  privacy_messages TEXT DEFAULT 'everyone' CHECK (privacy_messages IN ('everyone', 'contacts')),
  privacy_read_receipts BOOLEAN DEFAULT true,
  username_changed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS profiles_username_idx ON profiles(username);

-- 2. CHATS
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  is_group BOOLEAN DEFAULT false,
  avatar_url TEXT,
  created_by UUID REFERENCES profiles(id),
  last_message TEXT,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. CHAT_PARTICIPANTS
CREATE TABLE IF NOT EXISTS chat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT now(),
  last_read_at TIMESTAMPTZ,
  is_muted BOOLEAN DEFAULT false,
  UNIQUE(chat_id, user_id)
);
CREATE INDEX IF NOT EXISTS chat_participants_user_idx ON chat_participants(user_id);
CREATE INDEX IF NOT EXISTS chat_participants_chat_idx ON chat_participants(chat_id);

-- 4. MESSAGES
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  content TEXT,
  type TEXT DEFAULT 'text',
  media_url TEXT,
  metadata JSONB,
  reply_to UUID REFERENCES messages(id),
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS messages_chat_idx ON messages(chat_id);
CREATE INDEX IF NOT EXISTS messages_sender_idx ON messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_created_idx ON messages(chat_id, created_at DESC);

-- 5. MESSAGE_STATUS
CREATE TABLE IF NOT EXISTS message_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  UNIQUE(message_id, user_id)
);
CREATE INDEX IF NOT EXISTS message_status_message_idx ON message_status(message_id);

-- 5b. MESSAGE_REACTIONS (Emoji tepkileri)
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);
CREATE INDEX IF NOT EXISTS message_reactions_message_idx ON message_reactions(message_id);

-- 5c. STARRED_MESSAGES (Yıldızlı mesajlar - her kullanıcı kendi yıldızlarını tutar)
CREATE TABLE IF NOT EXISTS starred_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  starred_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, user_id)
);
CREATE INDEX IF NOT EXISTS starred_messages_user_idx ON starred_messages(user_id, starred_at DESC);
CREATE INDEX IF NOT EXISTS starred_messages_message_idx ON starred_messages(message_id);

-- 6. CONTACTS
CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  nickname TEXT,
  is_blocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, contact_id)
);
CREATE INDEX IF NOT EXISTS contacts_user_idx ON contacts(user_id);

-- 7. STORIES
CREATE TABLE IF NOT EXISTS stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  media_url TEXT,
  type TEXT DEFAULT 'image',
  caption TEXT,
  duration INTEGER DEFAULT 5,
  views_count INTEGER DEFAULT 0,
  metadata JSONB,
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours'),
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS stories_user_idx ON stories(user_id);
CREATE INDEX IF NOT EXISTS stories_expires_idx ON stories(expires_at);

-- 8. STORY_VIEWS
CREATE TABLE IF NOT EXISTS story_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(story_id, viewer_id)
);

-- 9. CALLS
CREATE TABLE IF NOT EXISTS calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID REFERENCES chats(id),
  caller_id UUID REFERENCES profiles(id),
  type TEXT DEFAULT 'voice',
  status TEXT DEFAULT 'initiated',
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS calls_chat_idx ON calls(chat_id);
CREATE INDEX IF NOT EXISTS calls_caller_idx ON calls(caller_id);

-- 10. PUSH_TOKENS
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, token)
);

-- ============================================================================
-- PART 2: RLS VE POLICIES
-- ============================================================================

-- PROFILES RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- CHATS RLS
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their chats" ON chats;
CREATE POLICY "Users can view their chats" ON chats FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_participants WHERE chat_id = id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can create chats" ON chats;
CREATE POLICY "Users can create chats" ON chats FOR INSERT WITH CHECK (auth.uid() = created_by);

-- CHAT_PARTICIPANTS RLS
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their participations" ON chat_participants;
-- Kullanıcılar kendi katıldıkları sohbetlerin tüm katılımcılarını görebilir
CREATE POLICY "Users can view their participations" ON chat_participants FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM chat_participants cp 
    WHERE cp.chat_id = chat_participants.chat_id AND cp.user_id = auth.uid()
  )
);
DROP POLICY IF EXISTS "Users can update their participations" ON chat_participants;
CREATE POLICY "Users can update their participations" ON chat_participants FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can insert participations" ON chat_participants;
CREATE POLICY "Users can insert participations" ON chat_participants FOR INSERT WITH CHECK (true);

-- MESSAGES RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Chat participants can view messages" ON messages;
CREATE POLICY "Chat participants can view messages" ON messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_participants WHERE chat_id = messages.chat_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Chat participants can send messages" ON messages;
CREATE POLICY "Chat participants can send messages" ON messages FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (SELECT 1 FROM chat_participants WHERE chat_id = messages.chat_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can update own messages" ON messages;
CREATE POLICY "Users can update own messages" ON messages FOR UPDATE USING (sender_id = auth.uid());

-- MESSAGE_STATUS RLS
ALTER TABLE message_status ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view message status" ON message_status;
-- Kullanıcı kendi durumunu veya gönderdiği mesajların durumlarını görebilir
CREATE POLICY "Users can view message status" ON message_status FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM messages WHERE id = message_id AND sender_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can manage message status" ON message_status;
CREATE POLICY "Users can manage message status" ON message_status FOR ALL USING (user_id = auth.uid());

-- MESSAGE_REACTIONS RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view reactions" ON message_reactions;
CREATE POLICY "Users can view reactions" ON message_reactions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can add reactions" ON message_reactions;
CREATE POLICY "Users can add reactions" ON message_reactions FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can remove own reactions" ON message_reactions;
CREATE POLICY "Users can remove own reactions" ON message_reactions FOR DELETE USING (user_id = auth.uid());

-- CONTACTS RLS
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their contacts" ON contacts;
CREATE POLICY "Users can manage their contacts" ON contacts FOR ALL USING (user_id = auth.uid());

-- STORIES RLS
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Contacts can view stories" ON stories;
CREATE POLICY "Contacts can view stories" ON stories FOR SELECT USING (
  user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM contacts WHERE user_id = stories.user_id AND contact_id = auth.uid() AND is_blocked = false)
);
DROP POLICY IF EXISTS "Users can manage own stories" ON stories;
CREATE POLICY "Users can manage own stories" ON stories FOR ALL USING (user_id = auth.uid());

-- STORY_VIEWS RLS
ALTER TABLE story_views ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Story owners can view views" ON story_views;
CREATE POLICY "Story owners can view views" ON story_views FOR SELECT USING (
  EXISTS (SELECT 1 FROM stories WHERE id = story_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can record their views" ON story_views;
CREATE POLICY "Users can record their views" ON story_views FOR INSERT WITH CHECK (viewer_id = auth.uid());

-- CALLS RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Participants can view calls" ON calls;
CREATE POLICY "Participants can view calls" ON calls FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_participants WHERE chat_id = calls.chat_id AND user_id = auth.uid())
);

-- PUSH_TOKENS RLS
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own tokens" ON push_tokens;
CREATE POLICY "Users can manage own tokens" ON push_tokens FOR ALL USING (user_id = auth.uid());

-- ============================================================================
-- PART 3: FUNCTIONS & TRIGGERS
-- ============================================================================

-- Yeni kullanıcı -> otomatik profil
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Yeni mesaj -> chat güncelle
CREATE OR REPLACE FUNCTION handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chats SET 
    last_message = NEW.content,
    last_message_at = NEW.created_at,
    updated_at = now()
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_created ON messages;
CREATE TRIGGER on_message_created
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION handle_new_message();

-- ============================================================================
-- USER SESSIONS / LINKED DEVICES
-- ============================================================================

-- Kullanıcı oturum bilgileri (linked devices için)
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  
  -- Cihaz bilgileri
  device_name TEXT NOT NULL,
  device_type TEXT NOT NULL CHECK (device_type IN ('mobile', 'web', 'desktop')),
  device_os TEXT,
  device_model TEXT,
  
  -- App bilgileri
  app_version TEXT,
  user_agent TEXT,
  
  -- Lokasyon bilgileri
  ip_address TEXT,
  country TEXT,
  city TEXT,
  
  -- Session bilgileri
  last_active_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  
  -- Meta
  is_current BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS user_sessions_last_active_idx ON user_sessions(last_active_at);
CREATE INDEX IF NOT EXISTS user_sessions_is_current_idx ON user_sessions(is_current);

-- RLS Policies
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sessions"
  ON user_sessions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sessions"
  ON user_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sessions"
  ON user_sessions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sessions"
  ON user_sessions FOR DELETE
  USING (auth.uid() = user_id);

-- Eski session'ları temizle (30 günden eski)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
  DELETE FROM user_sessions 
  WHERE last_active_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TAMAMLANDI!
-- ============================================================================
