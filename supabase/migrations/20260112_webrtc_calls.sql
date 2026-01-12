-- ============================================================================
-- WebRTC 1-1 Calls Migration
-- ============================================================================

-- calls tablosuna yeni kolonlar ekle (varsa hata vermemesi için IF NOT EXISTS yok, önce kontrol)
DO $$ 
BEGIN
  -- callee_id kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='callee_id') THEN
    ALTER TABLE calls ADD COLUMN callee_id UUID REFERENCES profiles(id);
  END IF;

  -- offer_sdp kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='offer_sdp') THEN
    ALTER TABLE calls ADD COLUMN offer_sdp TEXT;
  END IF;

  -- answer_sdp kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='answer_sdp') THEN
    ALTER TABLE calls ADD COLUMN answer_sdp TEXT;
  END IF;

  -- ringing_at kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='ringing_at') THEN
    ALTER TABLE calls ADD COLUMN ringing_at TIMESTAMPTZ;
  END IF;

  -- accepted_at kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='accepted_at') THEN
    ALTER TABLE calls ADD COLUMN accepted_at TIMESTAMPTZ;
  END IF;

  -- connected_at kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='connected_at') THEN
    ALTER TABLE calls ADD COLUMN connected_at TIMESTAMPTZ;
  END IF;

  -- end_reason kolonu
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='calls' AND column_name='end_reason') THEN
    ALTER TABLE calls ADD COLUMN end_reason TEXT;
  END IF;
END $$;

-- status kolonu constraint'i güncelle (eski 'initiated' yerine 'ringing')
-- Önce eski constraint'i kaldır, sonra yeni ekle
DO $$
BEGIN
  -- Mevcut status değerlerini güncelle
  UPDATE calls SET status = 'ended' WHERE status = 'initiated';
  
  -- Yeni constraint ekle (varsa kaldır önce)
  ALTER TABLE calls DROP CONSTRAINT IF EXISTS calls_status_check;
  ALTER TABLE calls ADD CONSTRAINT calls_status_check 
    CHECK (status IN ('ringing', 'connected', 'ended', 'rejected', 'missed', 'busy'));
  
  -- type constraint güncelle
  ALTER TABLE calls DROP CONSTRAINT IF EXISTS calls_type_check;
  ALTER TABLE calls ADD CONSTRAINT calls_type_check 
    CHECK (type IN ('voice', 'video'));
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'Constraint update skipped: %', SQLERRM;
END $$;

-- callee_id index
CREATE INDEX IF NOT EXISTS calls_callee_idx ON calls(callee_id);
CREATE INDEX IF NOT EXISTS calls_status_idx ON calls(status);

-- ============================================================================
-- ICE_CANDIDATES tablosu (WebRTC ICE candidate exchange)
-- ============================================================================
CREATE TABLE IF NOT EXISTS ice_candidates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  call_id UUID REFERENCES calls(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  candidate TEXT NOT NULL,
  sdp_mid TEXT,
  sdp_m_line_index INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ice_candidates_call_idx ON ice_candidates(call_id);

-- ============================================================================
-- RLS Policies
-- ============================================================================

-- CALLS RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi aramalarını görebilir (caller veya callee)
DROP POLICY IF EXISTS "Users can view their calls" ON calls;
CREATE POLICY "Users can view their calls" ON calls FOR SELECT USING (
  auth.uid() = caller_id OR auth.uid() = callee_id
);

-- Kullanıcılar arama başlatabilir (caller olarak)
DROP POLICY IF EXISTS "Users can create calls" ON calls;
CREATE POLICY "Users can create calls" ON calls FOR INSERT WITH CHECK (
  auth.uid() = caller_id
);

-- Kullanıcılar kendi aramalarını güncelleyebilir
DROP POLICY IF EXISTS "Users can update their calls" ON calls;
CREATE POLICY "Users can update their calls" ON calls FOR UPDATE USING (
  auth.uid() = caller_id OR auth.uid() = callee_id
);

-- Kullanıcılar kendi aramalarını silebilir
DROP POLICY IF EXISTS "Users can delete their calls" ON calls;
CREATE POLICY "Users can delete their calls" ON calls FOR DELETE USING (
  auth.uid() = caller_id OR auth.uid() = callee_id
);

-- ICE_CANDIDATES RLS
ALTER TABLE ice_candidates ENABLE ROW LEVEL SECURITY;

-- Aramanın tarafları ICE candidate'leri görebilir
DROP POLICY IF EXISTS "Call participants can view ice candidates" ON ice_candidates;
CREATE POLICY "Call participants can view ice candidates" ON ice_candidates FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM calls 
    WHERE calls.id = ice_candidates.call_id 
    AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
  )
);

-- Aramanın tarafları ICE candidate ekleyebilir
DROP POLICY IF EXISTS "Call participants can insert ice candidates" ON ice_candidates;
CREATE POLICY "Call participants can insert ice candidates" ON ice_candidates FOR INSERT WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1 FROM calls 
    WHERE calls.id = call_id 
    AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
  )
);

-- ============================================================================
-- Realtime subscription için
-- ============================================================================
-- calls ve ice_candidates tablolarını realtime'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE calls;
ALTER PUBLICATION supabase_realtime ADD TABLE ice_candidates;
