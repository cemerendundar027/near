// Supabase konfigürasyonu
//
// Bu değerleri Supabase Dashboard'dan alın:
// 1. https://supabase.com/dashboard adresine gidin
// 2. Projenizi seçin
// 3. Sol menüden "Project Settings" > "API" bölümüne gidin
// 4. Aşağıdaki değerleri kopyalayın

class SupabaseConfig {
  // Project URL - "Project URL" bölümünden
  static const String url = 'https://uskgzwhhopfwklwcqjaj.supabase.co';
  
  // Anon Key - "Project API keys" bölümünden "anon public" key
  static const String anonKey = 'sb_publishable_UXg-6IEgqntgAMB8hOrn7Q_Gb5J2PeO';
  
  // Service Role Key - Sadece backend için (Flutter'da KULLANMAYIN!)
  // static const String serviceKey = 'YOUR_SERVICE_KEY';
}
