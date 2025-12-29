-- Stories tablosuna metadata kolonu ekle (eğer yoksa)
ALTER TABLE stories 
ADD COLUMN IF NOT EXISTS metadata JSONB;

-- Kolonun var olduğunu kontrol et
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'stories' AND column_name = 'metadata';

