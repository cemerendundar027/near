-- ═══════════════════════════════════════════════════════════════════════════
-- WebRTC Schema Fixes - 12 Ocak 2026
-- ═══════════════════════════════════════════════════════════════════════════
-- 
-- Bu migration şunları düzeltir:
-- 1. calls tablosunda 'call_type' -> 'type' kolon ismi
-- 2. 'duration' -> 'duration_seconds' kolon ismi
-- 3. Eksik indeksler
-- 4. Trigger güncellemeleri
--

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. CALLS TABLOSU - Kolon İsimlerini Düzelt
-- ═══════════════════════════════════════════════════════════════════════════

-- Eğer 'call_type' kolonu varsa 'type' olarak yeniden adlandır
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calls' AND column_name = 'call_type'
    ) THEN
        ALTER TABLE calls RENAME COLUMN call_type TO type;
        RAISE NOTICE 'Column call_type renamed to type';
    END IF;
END $$;

-- Eğer 'duration' kolonu varsa 'duration_seconds' olarak yeniden adlandır
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'calls' AND column_name = 'duration'
    ) THEN
        ALTER TABLE calls RENAME COLUMN duration TO duration_seconds;
        RAISE NOTICE 'Column duration renamed to duration_seconds';
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. TRIGGER'LARI GÜNCELLE
-- ═══════════════════════════════════════════════════════════════════════════

-- Önce eski trigger'ı sil
DROP TRIGGER IF EXISTS trg_calculate_call_duration ON calls;

-- Yeni trigger function (duration_seconds ile)
CREATE OR REPLACE FUNCTION calculate_call_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'ended' AND NEW.connected_at IS NOT NULL THEN
        NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.ended_at - NEW.connected_at))::INT;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger'ı yeniden oluştur
CREATE TRIGGER trg_calculate_call_duration
    BEFORE UPDATE ON calls
    FOR EACH ROW
    WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.status = 'ended')
    EXECUTE FUNCTION calculate_call_duration();

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. CLEANUP FUNCTION'INI GÜNCELLE
-- ═══════════════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. CALL_HISTORY VIEW'INI GÜNCELLE
-- ═══════════════════════════════════════════════════════════════════════════

DROP VIEW IF EXISTS call_history;

CREATE OR REPLACE VIEW call_history AS
SELECT 
    c.id,
    c.type,
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

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. REALTIME PUBLICATION KONTROL
-- ═══════════════════════════════════════════════════════════════════════════

-- calls tablosunu realtime'a ekle (eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'calls'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE calls;
        RAISE NOTICE 'Table calls added to realtime publication';
    END IF;
END $$;

-- ice_candidates tablosunu realtime'a ekle (eğer yoksa)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'ice_candidates'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE ice_candidates;
        RAISE NOTICE 'Table ice_candidates added to realtime publication';
    END IF;
END $$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. PERFORMANS İYİLEŞTİRMELERİ
-- ═══════════════════════════════════════════════════════════════════════════

-- Eksik indeksler ekle
CREATE INDEX IF NOT EXISTS idx_calls_type ON calls(type);
CREATE INDEX IF NOT EXISTS idx_calls_ended_at ON calls(ended_at DESC) WHERE ended_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ice_created_at ON ice_candidates(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════
-- TAMAMLANDI
-- ═══════════════════════════════════════════════════════════════════════════

-- Migration başarıyla tamamlandı
SELECT 'WebRTC schema fixes applied successfully!' as message;
