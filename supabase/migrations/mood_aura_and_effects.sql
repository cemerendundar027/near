-- ============================================================================
-- MOOD AURA & MESSAGE EFFECTS - DATABASE MIGRATION
-- ============================================================================

-- 1. Profiles tablosuna mood_aura kolonu ekle
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS mood_aura TEXT DEFAULT 'none' 
  CHECK (mood_aura IN ('none', 'happy', 'calm', 'excited', 'focused', 'creative', 'love', 'mysterious'));

-- 2. Messages tablosuna effect kolonu ekle
ALTER TABLE messages ADD COLUMN IF NOT EXISTS effect TEXT DEFAULT NULL
  CHECK (effect IS NULL OR effect IN ('confetti', 'hearts', 'fireworks', 'stars', 'bubbles', 'snow', 'laser', 'shake'));

-- Index for faster queries
CREATE INDEX IF NOT EXISTS profiles_mood_aura_idx ON profiles(mood_aura);


