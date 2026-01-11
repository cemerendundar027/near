-- ╔═══════════════════════════════════════════════════════════════════════════╗
-- ║                    PHASE 6: WEBRTC VOICE/VIDEO CALLS                       ║
-- ║                         Supabase Schema Migration                           ║
-- ╚═══════════════════════════════════════════════════════════════════════════╝
-- 
-- Bu dosyayı Supabase Dashboard > SQL Editor'da çalıştırın.
-- Sırasıyla: 1) Tablolar, 2) RLS Policies, 3) Realtime, 4) Functions
--

-- ═══════════════════════════════════════════════════════════════════════════════
-- 1. CALLS TABLE - Arama kayıtları
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Arama tarafları
    caller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    callee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Arama tipi ve durumu
    call_type TEXT NOT NULL CHECK (call_type IN ('voice', 'video')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- Arama başlatıldı, yanıt bekleniyor
        'ringing',      -- Karşı tarafta çalıyor
        'accepted',     -- Kabul edildi, bağlantı kuruluyor
        'connected',    -- Aktif görüşme
        'ended',        -- Normal bitiş
        'missed',       -- Cevapsız
        'declined',     -- Reddedildi
        'busy',         -- Meşgul
        'failed'        -- Bağlantı hatası
    )),
    
    -- WebRTC Signaling
    offer_sdp TEXT,              -- Caller'ın SDP offer'ı
    answer_sdp TEXT,             -- Callee'nin SDP answer'ı
    
    -- Zaman bilgileri
    created_at TIMESTAMPTZ DEFAULT NOW(),
    ringing_at TIMESTAMPTZ,      -- Çalmaya başladığı an
    accepted_at TIMESTAMPTZ,     -- Kabul edildiği an
    connected_at TIMESTAMPTZ,    -- Bağlantı kurulduğu an
    ended_at TIMESTAMPTZ,        -- Bitiş zamanı
    
    -- Arama kalitesi ve istatistikler
    duration_seconds INT,        -- Görüşme süresi (saniye)
    end_reason TEXT,             -- Bitiş nedeni (user_hangup, network_error, etc.)
    quality_score INT,           -- 1-5 arası kalite puanı
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for calls
CREATE INDEX IF NOT EXISTS idx_calls_caller ON calls(caller_id);
CREATE INDEX IF NOT EXISTS idx_calls_callee ON calls(callee_id);
CREATE INDEX IF NOT EXISTS idx_calls_status ON calls(status);
CREATE INDEX IF NOT EXISTS idx_calls_created_at ON calls(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_participants ON calls(caller_id, callee_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2. ICE_CANDIDATES TABLE - WebRTC ICE adayları
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS ice_candidates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
    
    -- Hangi taraftan geldiği
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- ICE Candidate bilgileri
    candidate TEXT NOT NULL,          -- ICE candidate string
    sdp_mid TEXT,                     -- Media stream identification
    sdp_m_line_index INT,             -- Media line index
    
    -- Zaman
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- İşlenme durumu
    processed BOOLEAN DEFAULT FALSE
);

-- Indexes for ice_candidates
CREATE INDEX IF NOT EXISTS idx_ice_call ON ice_candidates(call_id);
CREATE INDEX IF NOT EXISTS idx_ice_sender ON ice_candidates(sender_id);
CREATE INDEX IF NOT EXISTS idx_ice_unprocessed ON ice_candidates(call_id, processed) WHERE NOT processed;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 3. CALL_EVENTS TABLE - Arama olayları (isteğe bağlı, debug için)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS call_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL REFERENCES calls(id) ON DELETE CASCADE,
    
    -- Olay bilgileri
    event_type TEXT NOT NULL,         -- 'offer_sent', 'answer_received', 'ice_added', 'connected', etc.
    sender_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Olay detayları
    data JSONB DEFAULT '{}'::jsonb,
    
    -- Zaman
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for call_events
CREATE INDEX IF NOT EXISTS idx_call_events_call ON call_events(call_id);
CREATE INDEX IF NOT EXISTS idx_call_events_created ON call_events(call_id, created_at);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ═══════════════════════════════════════════════════════════════════════════════

-- Enable RLS
ALTER TABLE calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE ice_candidates ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_events ENABLE ROW LEVEL SECURITY;

-- CALLS POLICIES
-- Kullanıcı sadece kendi aramalarını görebilir
CREATE POLICY "Users can view their own calls"
    ON calls FOR SELECT
    USING (auth.uid() = caller_id OR auth.uid() = callee_id);

-- Kullanıcı arama başlatabilir
CREATE POLICY "Users can create calls"
    ON calls FOR INSERT
    WITH CHECK (auth.uid() = caller_id);

-- Taraflar aramayı güncelleyebilir
CREATE POLICY "Participants can update calls"
    ON calls FOR UPDATE
    USING (auth.uid() = caller_id OR auth.uid() = callee_id);

-- ICE_CANDIDATES POLICIES
-- Arama katılımcıları ICE adaylarını görebilir
CREATE POLICY "Call participants can view ice candidates"
    ON ice_candidates FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM calls 
            WHERE calls.id = ice_candidates.call_id 
            AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
        )
    );

-- Arama katılımcıları ICE adayı ekleyebilir
CREATE POLICY "Call participants can insert ice candidates"
    ON ice_candidates FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM calls 
            WHERE calls.id = ice_candidates.call_id 
            AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
        )
    );

-- Arama katılımcıları ICE adaylarını güncelleyebilir (processed flag)
CREATE POLICY "Call participants can update ice candidates"
    ON ice_candidates FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM calls 
            WHERE calls.id = ice_candidates.call_id 
            AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
        )
    );

-- CALL_EVENTS POLICIES
-- Arama katılımcıları olayları görebilir
CREATE POLICY "Call participants can view events"
    ON call_events FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM calls 
            WHERE calls.id = call_events.call_id 
            AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
        )
    );

-- Arama katılımcıları olay ekleyebilir
CREATE POLICY "Call participants can insert events"
    ON call_events FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM calls 
            WHERE calls.id = call_events.call_id 
            AND (calls.caller_id = auth.uid() OR calls.callee_id = auth.uid())
        )
    );

-- ═══════════════════════════════════════════════════════════════════════════════
-- 5. REALTIME SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- calls tablosu için realtime aktifleştir
ALTER PUBLICATION supabase_realtime ADD TABLE calls;

-- ice_candidates tablosu için realtime aktifleştir
ALTER PUBLICATION supabase_realtime ADD TABLE ice_candidates;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 6. HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Aktif arama kontrolü (kullanıcı zaten bir aramada mı?)
CREATE OR REPLACE FUNCTION is_user_in_call(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM calls
        WHERE (caller_id = user_id OR callee_id = user_id)
        AND status IN ('pending', 'ringing', 'accepted', 'connected')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Arama süresini hesapla ve kaydet
CREATE OR REPLACE FUNCTION calculate_call_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'ended' AND NEW.connected_at IS NOT NULL THEN
        NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.ended_at - NEW.connected_at))::INT;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Arama bittiğinde süreyi hesapla
CREATE TRIGGER trg_calculate_call_duration
    BEFORE UPDATE ON calls
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'ended')
    EXECUTE FUNCTION calculate_call_duration();

-- Eski/tamamlanmamış aramaları temizle (cron job için)
CREATE OR REPLACE FUNCTION cleanup_stale_calls()
RETURNS void AS $$
BEGIN
    -- 2 dakikadan uzun süredir pending/ringing olan aramaları missed olarak işaretle
    UPDATE calls
    SET status = 'missed',
        ended_at = NOW(),
        end_reason = 'timeout'
    WHERE status IN ('pending', 'ringing')
    AND created_at < NOW() - INTERVAL '2 minutes';
    
    -- 1 saatten uzun süredir connected olan aramaları sonlandır (güvenlik)
    UPDATE calls
    SET status = 'ended',
        ended_at = NOW(),
        end_reason = 'max_duration'
    WHERE status = 'connected'
    AND connected_at < NOW() - INTERVAL '1 hour';
    
    -- 24 saatten eski ICE adaylarını temizle
    DELETE FROM ice_candidates
    WHERE created_at < NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 7. VIEWS (Opsiyonel - Arama geçmişi için)
-- ═══════════════════════════════════════════════════════════════════════════════

-- Kullanıcının arama geçmişi view'ı
CREATE OR REPLACE VIEW call_history AS
SELECT 
    c.id,
    c.call_type,
    c.status,
    c.created_at,
    c.ended_at,
    c.duration_seconds,
    c.caller_id,
    c.callee_id,
    -- Caller bilgileri
    caller.username as caller_username,
    caller.full_name as caller_name,
    caller.avatar_url as caller_avatar,
    -- Callee bilgileri
    callee.username as callee_username,
    callee.full_name as callee_name,
    callee.avatar_url as callee_avatar
FROM calls c
LEFT JOIN profiles caller ON c.caller_id = caller.id
LEFT JOIN profiles callee ON c.callee_id = callee.id
ORDER BY c.created_at DESC;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 8. GRANT PERMISSIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Authenticated users için izinler
GRANT SELECT, INSERT, UPDATE ON calls TO authenticated;
GRANT SELECT, INSERT, UPDATE ON ice_candidates TO authenticated;
GRANT SELECT, INSERT ON call_events TO authenticated;
GRANT SELECT ON call_history TO authenticated;

-- Function izinleri
GRANT EXECUTE ON FUNCTION is_user_in_call(UUID) TO authenticated;

-- ═══════════════════════════════════════════════════════════════════════════════
-- NOTLAR:
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- 1. STUN/TURN Sunucuları:
--    WebRTC bağlantısı için STUN/TURN sunucuları gerekli. Önerilen:
--    - Google STUN: stun:stun.l.google.com:19302
--    - Twilio TURN: https://www.twilio.com/stun-turn
--    - Metered TURN: https://www.metered.ca/tools/openrelay/
--
-- 2. Push Notifications:
--    Gelen arama bildirimi için push notification gerekli.
--    Flutter paketi: firebase_messaging + flutter_local_notifications
--
-- 3. Cleanup Cron Job:
--    cleanup_stale_calls() fonksiyonunu düzenli çalıştırmak için
--    Supabase Dashboard > Database > Extensions > pg_cron kullanın:
--    
--    SELECT cron.schedule('cleanup-stale-calls', '*/5 * * * *', 
--           'SELECT cleanup_stale_calls()');
--
-- 4. Flutter Paketleri (pubspec.yaml'a ekleyin):
--    flutter_webrtc: ^0.9.47
--    permission_handler: ^11.0.1 (zaten var)
--
-- ═══════════════════════════════════════════════════════════════════════════════
