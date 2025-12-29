# Near - Product Requirements Document (PRD)

> **Near** - Modern, WhatsApp tarzı tasarıma sahip Flutter tabanlı mesajlaşma uygulaması
>
> **Versiyon:** 2.0.0  
> **Platform:** iOS, Android, Web, macOS, Linux, Windows  
> **SDK:** Flutter ^3.10.4  
> **Backend:** Supabase (PostgreSQL + Realtime + Storage + Auth)  
> **Tema:** NearTheme (Primary: #7B3FF2 Eflatun)

---

## 🎯 YOL HARİTASI (ROADMAP)

### 🚀 v1.0 RELEASE CHECKLIST (Eksiksiz Sürüm)

| Faz | Açıklama | Durum | v1 Gerekli |
|-----|----------|-------|------------|
| 0 | Temel Altyapı | ✅ | Evet |
| 1 | Temel Mesajlaşma | ✅ | Evet |
| 2 | Profil & Kişiler | ✅ | Evet |
| 3 | Grup Sohbetleri | ✅ | Evet |
| 4 | Medya Paylaşımı | ✅ | Evet |
| 5 | Story Sistemi | ✅ | Evet |
| 6 | Sesli/Görüntülü Arama | ⬜ | **Evet** |
| 7 | Push Notifications | ⬜ | **Evet** |
| 8 | Güvenlik (Temel) | ⬜ | **Evet** |
| 9 | Offline & Sync | ⬜ | Hayır (v1.1) |
| 10 | Test & Deployment | ⬜ | **Evet** |

**v1.0 için Tamamlanması Gereken:** Faz 6, 7, 8 (temel), 10
**Tahmini Süre:** 4-5 hafta

---

### Faz 0: Mevcut Durum ✅
- [x] Tüm UI/Frontend tamamlandı (165+ özellik)
- [x] Supabase entegrasyonu başlatıldı
- [x] Auth sistemi çalışıyor (Email/Password)
- [x] Database şeması hazır (10 tablo)
- [x] RLS politikaları tanımlı
- [x] ChatService temel fonksiyonlar
- [x] Realtime subscription altyapısı

---

### 🚀 Faz 1: Temel Mesajlaşma ✅
**Hedef:** Kullanıcılar gerçek zamanlı mesajlaşabilsin

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 1.1 | Profil oluşturma/güncelleme | ✅ | P0 | ProfileEditPage backend'e bağlandı |
| 1.2 | Kullanıcı arama | ✅ | P0 | searchUsers, getAllUsers Supabase'den |
| 1.3 | 1-1 sohbet oluşturma | ✅ | P0 | createDirectChat + NewChatPage UI |
| 1.4 | Mesaj gönderme | ✅ | P0 | sendMessage + ChatDetailPage _sendSupabaseMessage |
| 1.5 | Mesaj alma (Realtime) | ✅ | P0 | subscribeToMessages + ChatDetailPage entegrasyonu |
| 1.6 | Sohbet listesi | ✅ | P0 | loadChats + ChatsPage entegrasyonu |
| 1.7 | Mesaj durumu (sent/delivered/read) | ✅ | P1 | markMessageAsDelivered/Read + UI entegrasyonu |
| 1.8 | Yazıyor göstergesi | ✅ | P1 | subscribeToTyping + sendTypingIndicator + UI |
| 1.9 | Online/Offline durumu | ✅ | P1 | setOnlineStatus + isOtherUserOnline + UI |

**SQL Tabloları:** `profiles`, `chats`, `chat_participants`, `messages`, `message_status`

---

### 📱 Faz 2: Profil & Kişiler
**Hedef:** Kullanıcı profili yönetimi ve kişi listesi

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 2.1 | Profil fotoğrafı yükleme | ✅ | P0 | Supabase Storage + avatar upload UI + eski avatar silme |
| 2.2 | Profil bilgisi güncelleme | ✅ | P0 | Profil adı, bio, telefon, tam backend entegrasyonu |
| 2.3 | Username sistemi | ✅ | P0 | Unique/validasyon, anlık kontrol, hata gösterimi |
| 2.4 | Kişi ekleme | ✅ | P1 | ContactService + ContactsPage UI entegrasyonu |
| 2.5 | Kişi engelleme | ✅ | P1 | Block/Unblock + BlockedUsersPage backend bağlantısı |
| 2.6 | Son görülme ayarları | ✅ | P2 | Privacy settings (last_seen, profile_photo, about, read_receipts) |
| 2.7 | QR ile kişi ekleme | ✅ | P2 | `qr_code_scanner` + gerçek kamera tarama |

**SQL Tabloları:** `profiles`, `contacts`

---

### 👥 Faz 3: Grup Sohbetleri
**Hedef:** Çoklu kullanıcı sohbetleri

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 3.1 | Grup oluşturma | ✅ | P0 | `createGroupChat` + CreateGroupPage UI |
| 3.2 | Grup üyesi ekleme | ✅ | P0 | `addMembersToGroup` + GroupInfoPage UI |
| 3.3 | Grup üyesi çıkarma | ✅ | P1 | `removeMemberFromGroup` + Admin kontrolü |
| 3.4 | Grup admin yönetimi | ✅ | P1 | `makeUserAdmin`, `removeUserAdmin` |
| 3.5 | Grup bilgisi düzenleme | ✅ | P1 | `updateGroupName`, `updateGroupAvatar` |
| 3.6 | @Mention sistemi | ✅ | P2 | `parseMentions`, `sendMessageWithMentions`, UI önerileri |
| 3.7 | Gruptan ayrılma | ✅ | P1 | `leaveGroup` + UI dialog |

**SQL Tabloları:** `chats`, `chat_participants`

---

### 📷 Faz 4: Medya Paylaşımı
**Hedef:** Fotoğraf, video, dosya paylaşımı

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 4.1 | Fotoğraf gönderme | ✅ | P0 | `sendPhoto` + Supabase Storage + UI entegrasyonu |
| 4.2 | Video gönderme | ✅ | P1 | `sendVideo` + thumbnail desteği + UI entegrasyonu |
| 4.3 | Sesli mesaj kayıt/gönder | ✅ | P1 | `AudioService` + `record` paketi + gerçek kayıt |
| 4.4 | Dosya gönderme | ✅ | P2 | `file_picker` + `sendFile` + gerçek dosya seçimi |
| 4.5 | Medya sıkıştırma | ✅ | P1 | ImagePicker imageQuality + maxWidth/Height |
| 4.6 | Medya önizleme | ✅ | P1 | `_MessageBubble` medya tipleri (image/video/voice/file) |
| 4.7 | Medya galerisi | ✅ | P2 | UI hazır |
| 4.8 | GIF gönderme | ✅ | P2 | Tenor API + gerçek arama + gerçek GIF'ler |
| 4.9 | Konum paylaşma | ✅ | P2 | `geolocator` + `geocoding` + gerçek GPS |
| 4.10 | Kişi paylaşma | ✅ | P3 | `flutter_contacts` + gerçek rehber erişimi |

**Eklenen Paketler:** `record`, `just_audio`, `file_picker`, `path_provider`, `qr_code_scanner`, `geolocator`, `geocoding`, `flutter_contacts`, `permission_handler`, `http`

**SQL Tabloları:** `messages` (type, media_url, metadata)
**Storage Bucket:** `media`

---

### 📖 Faz 5: Story Sistemi ✅
**Hedef:** 24 saat geçerli hikayeler

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 5.1 | Story oluşturma | ✅ | P1 | `StoryService` + Supabase Storage |
| 5.2 | Story görüntüleme | ✅ | P1 | Gerçek story'ler Supabase'den |
| 5.3 | Story görüntüleyenler | ✅ | P1 | `story_views` tablosu entegrasyonu |
| 5.4 | Story silme | ✅ | P1 | `deleteStory` + Storage cleanup |
| 5.5 | 24 saat expiry | ✅ | P2 | `expires_at` filtresi + SQL default |
| 5.6 | Story yanıtlama | ✅ | P2 | UI + DM reply (TODO: ChatService bağlantısı) |

**Yeni Dosyalar:** `lib/shared/story_service.dart`
**SQL Tabloları:** `stories` (metadata eklendi), `story_views`
**Storage Bucket:** `stories`

---

### 📞 Faz 6: Sesli/Görüntülü Arama
**Hedef:** WebRTC ile gerçek zamanlı arama

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 6.1 | Arama başlatma | ⬜ | P1 | `calls` tablosu var |
| 6.2 | WebRTC signaling | ⬜ | P1 | Supabase Realtime |
| 6.3 | Sesli arama | ⬜ | P1 | flutter_webrtc |
| 6.4 | Görüntülü arama | ⬜ | P2 | flutter_webrtc |
| 6.5 | Arama geçmişi | ⬜ | P1 | `calls` tablosu |
| 6.6 | Grup araması | ⬜ | P3 | Gelişmiş WebRTC |
| 6.7 | CallKit (iOS) | ⬜ | P1 | Native arama UI |
| 6.8 | ConnectionService (Android) | ⬜ | P1 | Native arama UI |

**SQL Tabloları:** `calls`
**Gerekli Paketler:** `flutter_webrtc`, `flutter_callkit_incoming`
**Tahmini Süre:** 2-3 hafta

---

### 🔔 Faz 7: Push Notifications & Firebase
**Hedef:** Uygulama kapalıyken bildirim

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 7.1 | Firebase projesi oluştur | ⬜ | P0 | console.firebase.google.com |
| 7.2 | FCM entegrasyonu (Android) | ⬜ | P0 | google-services.json |
| 7.3 | APNs entegrasyonu (iOS) | ⬜ | P0 | APNs key + GoogleService-Info.plist |
| 7.4 | Push token kaydetme | ⬜ | P0 | `push_tokens` tablosu var |
| 7.5 | Mesaj bildirimi | ⬜ | P0 | Supabase Edge Function |
| 7.6 | Arama bildirimi | ⬜ | P1 | VoIP push |
| 7.7 | Bildirim ayarları | ✅ | P1 | UI hazır |
| 7.8 | Firebase Crashlytics | ⬜ | P1 | Hata takibi |
| 7.9 | Firebase Analytics | ⬜ | P2 | Kullanım istatistikleri |

**SQL Tabloları:** `push_tokens`
**Gerekli Paketler:** `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`

---

### 🔐 Faz 8: Güvenlik & Gizlilik
**Hedef:** Temel güvenlik (v1) + E2E şifreleme (v2)

#### v1 için Gerekli
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 8.1 | SSL Pinning | ⬜ | P0 | MITM koruması |
| 8.2 | Secure Storage | ⬜ | P0 | flutter_secure_storage |
| 8.3 | Input validation | ⬜ | P0 | XSS/Injection koruması |
| 8.4 | Rate limiting | ⬜ | P1 | Supabase RLS + Edge Function |
| 8.5 | Biometric lock | ✅ | P1 | UI hazır, LocalAuth aktif |
| 8.6 | Session management | ⬜ | P1 | Token refresh, logout |

#### v2 için (İleri Seviye)
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 8.7 | E2E encryption (libsignal) | ⬜ | P2 | Signal protokolü |
| 8.8 | Key exchange | ⬜ | P2 | X3DH |
| 8.9 | Mesaj şifreleme | ⬜ | P2 | Double Ratchet |
| 8.10 | Kaybolan mesajlar | ✅ | P2 | UI hazır, backend gerekli |
| 8.11 | Ekran görüntüsü algılama | ⬜ | P3 | Platform API |

**Gerekli Paketler:** `flutter_secure_storage`, `local_auth`

---

### 💾 Faz 9: Offline & Sync (v1.1)
**Hedef:** Çevrimdışı kullanım - v1.1'de yapılacak

| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 9.1 | Local DB (Hive/SQLite) | 🔄 | P1 | Hive kurulu, genişletilecek |
| 9.2 | Offline mesaj kuyruğu | ⬜ | P1 | Pending messages |
| 9.3 | Sync mekanizması | ⬜ | P1 | Delta sync |
| 9.4 | Chat backup | ⬜ | P2 | Google Drive / iCloud |
| 9.5 | Chat restore | ⬜ | P2 | Import/Export |
| 9.6 | Media cache | ⬜ | P2 | Resim/video offline |

**Not:** v1.0'da temel Hive cache mevcut, tam offline destek v1.2'de

---

### 🧪 Faz 10: Test & Deployment
**Hedef:** Production-ready uygulama

#### 10.A - Yasal & Marka
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 10.A.1 | Privacy Policy | ⬜ | P0 | KVKK/GDPR uyumlu, web sayfası |
| 10.A.2 | Terms of Service | ⬜ | P0 | Kullanım koşulları |
| 10.A.3 | App ikonu tasarımı | ⬜ | P0 | 1024x1024 PNG |
| 10.A.4 | Splash screen | ⬜ | P1 | iOS/Android native |
| 10.A.5 | Store görselleri | ⬜ | P0 | Screenshots, feature graphic |
| 10.A.6 | App açıklaması | ⬜ | P0 | TR/EN store listing |

#### 10.B - Konfigürasyon
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 10.B.1 | Environment variables | ⬜ | P0 | API key'leri .env'e taşı |
| 10.B.2 | Production Supabase | ⬜ | P0 | Ayrı production projesi |
| 10.B.3 | Bundle ID/Package name | ⬜ | P0 | com.nearapp.near |
| 10.B.4 | App versioning | ⬜ | P1 | Semantic versioning |
| 10.B.5 | ProGuard/R8 (Android) | ⬜ | P1 | Code obfuscation |

#### 10.C - iOS Deployment
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 10.C.1 | Apple Developer hesabı | ⬜ | P0 | $99/yıl |
| 10.C.2 | App Store Connect | ⬜ | P0 | App oluştur |
| 10.C.3 | Certificates & Profiles | ⬜ | P0 | Distribution certificate |
| 10.C.4 | TestFlight beta | ⬜ | P1 | Beta test |
| 10.C.5 | App Store review | ⬜ | P0 | 1-3 gün |

#### 10.D - Android Deployment
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 10.D.1 | Google Play Console hesabı | ⬜ | P0 | $25 tek seferlik |
| 10.D.2 | Signing key oluştur | ⬜ | P0 | upload-keystore.jks |
| 10.D.3 | App Bundle (AAB) | ⬜ | P0 | Release build |
| 10.D.4 | Internal testing | ⬜ | P1 | Beta test |
| 10.D.5 | Play Store review | ⬜ | P0 | 1-7 gün |

#### 10.E - Test & Monitoring
| # | Görev | Durum | Öncelik | Notlar |
|---|-------|-------|---------|--------|
| 10.E.1 | Unit testler | ⬜ | P1 | Core logic |
| 10.E.2 | Widget testler | ⬜ | P2 | UI components |
| 10.E.3 | Integration testler | ⬜ | P2 | E2E flows |
| 10.E.4 | CI/CD pipeline | ⬜ | P1 | GitHub Actions / Codemagic |
| 10.E.5 | Crash reporting | ✅ | P1 | Firebase Crashlytics (Faz 7) |
| 10.E.6 | Performance monitoring | ⬜ | P2 | Firebase Performance |

**Tahmini Süre:** 1-2 hafta (hesap onayları dahil)

---

## 📊 MEVCUT BACKEND DURUMU

### Supabase Konfigürasyonu
```
URL: https://uskgzwhhopfwklwcqjaj.supabase.co
Proje: Near Messaging App
Bölge: EU (Frankfurt)
```

### Database Tabloları (10 adet)
| Tablo | Durum | RLS | Açıklama |
|-------|-------|-----|----------|
| `profiles` | ✅ | ✅ | Kullanıcı profilleri |
| `chats` | ✅ | ✅ | Sohbetler (1-1 ve grup) |
| `chat_participants` | ✅ | ✅ | Sohbet katılımcıları |
| `messages` | ✅ | ✅ | Mesajlar |
| `message_status` | ✅ | ✅ | Okundu/iletildi durumu |
| `contacts` | ✅ | ✅ | Kişi listesi |
| `stories` | ✅ | ✅ | Hikayeler |
| `story_views` | ✅ | ✅ | Story görüntüleyenler |
| `calls` | ✅ | ✅ | Arama kayıtları |
| `push_tokens` | ✅ | ✅ | Push bildirim tokenları |

### Storage Buckets (Oluşturulacak)
| Bucket | Durum | Kullanım |
|--------|-------|----------|
| `avatars` | ⬜ | Profil fotoğrafları |
| `media` | ⬜ | Sohbet medyaları |
| `stories` | ⬜ | Story medyaları |

### Servis Dosyaları
| Dosya | Durum | Açıklama |
|-------|-------|----------|
| `supabase_service.dart` | ✅ | Ana Supabase client |
| `auth_service.dart` | ✅ | Authentication işlemleri |
| `chat_service.dart` | ✅ | Mesajlaşma işlemleri |
| `contact_service.dart` | ✅ | Kişi yönetimi, engelleme, gizlilik ayarları |
| `chat_store.dart` | 🔄 | State management (kısmen mock) |
| `message_store.dart` | 🔄 | Mesaj state (mock data) |
| `network_service.dart` | ✅ | Ağ durumu |

---

## 🏗️ MİMARİ

### Veri Akışı
```
UI (Pages/Widgets)
       ↓↑
State Management (ChatStore, Provider)
       ↓↑
Service Layer (ChatService, AuthService)
       ↓↑
Supabase Client
       ↓↑
Supabase Backend (PostgreSQL + Realtime + Storage)
```

### Realtime Channels
| Channel | Kullanım |
|---------|----------|
| `chats:user_id` | Sohbet güncellemeleri |
| `messages:chat_id` | Mesaj güncellemeleri |
| `typing_chat_id` | Yazıyor göstergesi |
| `presence` | Online durumu |

---

## 📁 Proje Mimarisi

```
near/
├── lib/
│   ├── main.dart                      # Uygulama giriş noktası
│   ├── app/
│   │   ├── app.dart                   # MaterialApp + GoRouter yapılandırması
│   │   ├── app_settings.dart          # Uygulama ayarları (tema, font, wallpaper)
│   │   ├── root_tabs.dart             # Ana tab bar navigasyonu
│   │   └── theme.dart                 # NearTheme renk paleti ve tema
│   ├── config/
│   │   └── supabase_config.dart       # Supabase URL ve API key
│   ├── features/
│   │   ├── auth/
│   │   │   └── auth_page.dart         # Telefon doğrulama sayfası
│   │   ├── calls/
│   │   │   ├── calls_page.dart        # Arama geçmişi sayfası
│   │   │   └── call_screen.dart       # Aktif arama ekranı
│   │   ├── chat_detail/
│   │   │   ├── chat_detail_page.dart  # Sohbet detay sayfası
│   │   │   └── message_info_sheet.dart # Mesaj bilgi modalı
│   │   ├── chats/
│   │   │   ├── chats_page.dart        # Ana sohbet listesi
│   │   │   └── ...                    # Diğer chat sayfaları
│   │   ├── onboarding/
│   │   │   └── onboarding_page.dart   # İlk kullanım rehberi
│   │   ├── profile/
│   │   │   ├── profile_edit_page.dart # Profil düzenleme sayfası
│   │   │   └── user_profile_page.dart # Kullanıcı profil görüntüleme
│   │   ├── settings/
│   │   │   └── ...                    # Ayar sayfaları
│   │   ├── splash/
│   │   │   └── splash_page.dart       # Açılış ekranı
│   │   └── story/
│   │       ├── story_viewer_page.dart # Story görüntüleyici
│   │       └── story_create_page.dart # Story oluşturma sayfası
│   └── shared/
│       ├── supabase_service.dart      # ⭐ Supabase client
│       ├── auth_service.dart          # ⭐ Auth işlemleri
│       ├── chat_service.dart          # ⭐ Chat işlemleri (Realtime)
│       ├── chat_store.dart            # State management
│       ├── message_store.dart         # Mesaj state
│       ├── models.dart                # Veri modelleri
│       ├── network_service.dart       # Ağ durumu
│       └── widgets/                   # 28 Özel Widget
├── supabase/
│   └── schema.sql                     # Database şeması
├── pubspec.yaml                       # Bağımlılıklar
└── prd.md                             # Bu dosya
```

---

## 🎨 Tasarım Sistemi

### Renk Paleti (NearTheme)
| Renk | Hex | Kullanım |
|------|-----|----------|
| Primary | `#7B3FF2` | Ana eflatun |
| PrimaryDark | `#5A22C8` | Koyu eflatun |
| PrimarySoft | `#E9DEFF` | Açık eflatun |
| MyBubble | `#6C2FEA` | Gönderilen mesaj |
| TheirBubble | `#E6DAFF` | Alınan mesaj (light) |
| Online | `#25D366` | Çevrimiçi göstergesi |

---

## ✅ ÖZELLİK DURUMU

### Durum Açıklamaları
- ✅ **Tamamlandı** - Frontend + Backend çalışıyor
- 🔄 **Kısmen Hazır** - Frontend hazır, Backend kısmen var
- ⬜ **Bekliyor** - Frontend hazır, Backend yok

### 🏠 Ana Uygulama

| Durum | Özellik | Notlar |
|-------|---------|--------|
| ✅ | MaterialApp yapılandırması | |
| ✅ | Light/Dark tema desteği | |
| ✅ | GoRouter navigasyon | |
| ✅ | Supabase Auth | Email/Password, OTP |
| ⬜ | Push notification | FCM/APNs gerekli |

### 💬 Mesajlaşma

| Durum | Özellik | Notlar |
|-------|---------|--------|
| ✅ | Sohbet listesi | Supabase Realtime |
| ✅ | Mesaj gönderme/alma | Realtime |
| ✅ | Yazıyor göstergesi | Broadcast |
| 🔄 | Mesaj durumu | Tablo var, logic kısmen |
| 🔄 | Mesaj düzenleme/silme | Fields var |
| 🔄 | Yanıtlama/İletme | `reply_to` field var |

### 📷 Medya

| Durum | Özellik | Notlar |
|-------|---------|--------|
| ✅ | Emoji/GIF picker | |
| ✅ | Image editor | |
| 🔄 | Fotoğraf gönderme | Storage gerekli |
| 🔄 | Sesli mesaj | Storage gerekli |

### 👥 Kullanıcı & Profil

| Durum | Özellik | Notlar |
|-------|---------|--------|
| ✅ | Auth sistemi | Email/Password |
| ✅ | Profil güncelleme | ProfileEditPage → Supabase |
| ⬜ | Avatar yükleme | Storage gerekli |
| ✅ | Kullanıcı arama | searchUsers, getAllUsers |
| ✅ | Kişi ekleme | ContactService + UI |
| ✅ | Kişi engelleme | Block/Unblock + BlockedUsersPage |
| ✅ | Gizlilik ayarları | Son görülme, profil fotoğrafı, hakkında |

---

## 📊 Özet İstatistikler

### Tamamlanan
- **Frontend UI:** 165+ özellik ✅
- **Backend Fonksiyonları:** 25+ method ✅
- **Database Tabloları:** 10 tablo ✅

### ÖNCELİK SIRASI
1. **P0 (Bu Hafta):** Profil, 1-1 sohbet, mesajlaşma tamamen çalışır
2. **P1 (Sonraki 2 Hafta):** Medya paylaşımı, grup sohbetleri
3. **P2 (1 Ay):** Story, Push notifications, arama

---

## 🔧 GELİŞTİRİCİ NOTLARI

### Mevcut Test Kullanıcısı
```
Email: cemerendundar027@gmail.com
UUID: 790fe26e-19f7-4996-be08-bb134cc2931e
```

### Realtime Kullanımı
```dart
// Mesaj dinleme
chatService.subscribeToMessages(chatId);

// Typing göstergesi
chatService.subscribeToTyping(chatId, onTyping);

// Online durumu
chatService.setOnlineStatus(true);
```

---

## 📝 Sonraki Adım - v1.0 Release (Eksiksiz)

### ✅ Tamamlanan (Faz 0-5):
1. [x] Temel altyapı & Supabase
2. [x] Temel mesajlaşma
3. [x] Profil & Kişiler  
4. [x] Grup sohbetleri
5. [x] Medya paylaşımı
6. [x] Story sistemi
7. [x] Mock veri temizliği

### 🔴 v1.0 için Yapılacaklar (Sırayla):

#### 1️⃣ Faz 6 - Sesli/Görüntülü Arama (~2-3 hafta)
1. [ ] flutter_webrtc paketi ekle
2. [ ] STUN/TURN sunucu konfigürasyonu
3. [ ] WebRTC signaling (Supabase Realtime)
4. [ ] CallService oluştur
5. [ ] Sesli arama implementasyonu
6. [ ] Görüntülü arama implementasyonu
7. [ ] CallKit (iOS) entegrasyonu
8. [ ] ConnectionService (Android) entegrasyonu
9. [ ] Arama geçmişi backend bağlantısı

#### 2️⃣ Faz 7 - Push Notifications (~1 hafta)
1. [ ] Firebase projesi oluştur
2. [ ] FCM entegrasyonu (Android)
3. [ ] APNs entegrasyonu (iOS)
4. [ ] Push token kaydetme
5. [ ] Supabase Edge Function (mesaj bildirimi)
6. [ ] VoIP push (arama bildirimi)
7. [ ] Firebase Crashlytics

#### 3️⃣ Faz 8 - Temel Güvenlik (~3-4 gün)
1. [ ] flutter_secure_storage ekle
2. [ ] SSL Pinning
3. [ ] Input validation
4. [ ] Session management

#### 4️⃣ Faz 10 - Deployment (~1-2 hafta)
1. [ ] Privacy Policy oluştur
2. [ ] Terms of Service oluştur
3. [ ] App ikonu tasarımı
4. [ ] Store görselleri (screenshots)
5. [ ] Apple Developer hesabı ($99/yıl)
6. [ ] Google Play Console hesabı ($25)
7. [ ] Environment variables (.env)
8. [ ] Production Supabase projesi
9. [ ] TestFlight & Internal Testing
10. [ ] Store yayını

### 🟢 v1.1 için (Gelecek Güncelleme):
- Faz 9: Offline sync & backup
- E2E Encryption
- Grup araması

---

> **Son Güncelleme:** 28 Aralık 2024  
> **Hazırlayan:** Near Development Team  
> **Backend:** Supabase  
> **Durum:** Aktif Geliştirme - Faz 1-5 Tamamlandı 🚀

---

## 📝 Son Değişiklikler (27 Aralık 2024)

### ✅ Faz 2 Tamamlandı!
- ✅ **2.4 Kişi Ekleme:** `ContactService` oluşturuldu, `ContactsPage` güncellendi
- ✅ **2.5 Kişi Engelleme:** Block/Unblock fonksiyonları, `BlockedUsersPage` backend entegrasyonu
- ✅ **2.6 Son Görülme Ayarları:** Privacy settings (last_seen, profile_photo, about, read_receipts)
- ✅ **2.7 QR ile Kişi Ekleme:** `MyQRCodePage`, `QRScannerPage` backend entegrasyonu

### Yeni/Güncellenen Dosyalar:
- `lib/shared/contact_service.dart` - Kişi yönetimi servisi
- `lib/shared/widgets/qr_code.dart` - QR kod widget'ları (backend entegrasyonu)
- `lib/features/chats/search_contacts_pages.dart` - QR butonu eklendi
- `lib/app/app.dart` - QR rotaları eklendi

### Veritabanı Değişiklikleri:
```sql
-- profiles tablosuna eklenen privacy alanları:
privacy_last_seen TEXT DEFAULT 'everyone' CHECK (privacy_last_seen IN ('everyone', 'contacts', 'nobody'))
privacy_profile_photo TEXT DEFAULT 'everyone' CHECK (privacy_profile_photo IN ('everyone', 'contacts', 'nobody'))
privacy_about TEXT DEFAULT 'everyone' CHECK (privacy_about IN ('everyone', 'contacts', 'nobody'))
privacy_read_receipts BOOLEAN DEFAULT true
```

### QR Kod Formatı:
```
near://user/{userId}
```

---

## 📝 Son Değişiklikler (28 Aralık 2024)

### ✅ Faz 5 Tamamlandı!
- ✅ **5.1 Story Oluşturma:** `StoryService` oluşturuldu, fotoğraf ve metin story desteği
- ✅ **5.2 Story Görüntüleme:** `StoryViewerPage` Supabase'den gerçek story'leri yükler
- ✅ **5.3 Story Görüntüleyenler:** `story_views` tablosu entegrasyonu, görüntüleyenler listesi
- ✅ **5.4 Story Silme:** Storage ve database cleanup
- ✅ **5.5 24 Saat Expiry:** `expires_at` filtresi
- ✅ **5.6 Story Yanıtlama:** UI hazır, DM reply desteği

### 🔧 Mock Temizliği
- `ForwardMessagePage`: Mock veriler kaldırıldı, gerçek ChatService verileri kullanılıyor
- `ChatDetailPage`: Demo mesaj yükleme kaldırıldı, sadece Supabase kullanılıyor
- `ChatsPage`: Story listesi StoryService'den gerçek verilerle

---

## 📝 Son Değişiklikler (28 Aralık 2024 - 2)

### ✅ Yeni UX Özellikleri
- ✅ **Swipe to Reply:** Mesaja sağa/sola kaydırarak yanıtla
- ✅ **Çift Tıkla Beğen:** Mesaja çift tıklayarak kalp ❤️ tepkisi (animasyonlu)
- ✅ **Emoji Tepkileri:** Mesaja uzun basınca emoji tepki menüsü (❤️ 👍 😂 😮 😢 🙏)
- ✅ **Uygulama Kilidi:** PIN + Face ID / Touch ID desteği

### ✅ Kullanıcı Yönetimi
- ✅ **Kullanıcı Adı Kayıtta:** Kayıt sırasında benzersiz kullanıcı adı seçimi
- ✅ **90 Gün Kuralı:** Kullanıcı adı 90 günde bir değiştirilebilir
- ✅ **Kullanıcı Adı Arama:** Kullanıcı adı ile arama yapabilme
- ✅ **Mesaj Gizliliği:** Sadece rehberdekiler / herkes mesaj gönderebilir ayarı

### Yeni/Güncellenen Dosyalar:
- `lib/shared/app_lock_service.dart` - PIN + Biyometrik kilit servisi
- `lib/app/lock_screen.dart` - Kilit ekranı UI
- `lib/features/settings/app_lock_page.dart` - Kilit ayarları sayfası
- `lib/features/chat_detail/chat_detail_page.dart` - Swipe reply, double-tap like, emoji reactions
- `lib/shared/chat_service.dart` - `addReaction`, `getMessageReactions` metodları
- `lib/features/auth/auth_page.dart` - Kayıtta kullanıcı adı seçimi
- `lib/features/settings/privacy_page.dart` - Mesaj gizliliği ayarı

### Veritabanı Değişiklikleri:
```sql
-- profiles tablosuna:
privacy_messages TEXT DEFAULT 'everyone' CHECK (privacy_messages IN ('everyone', 'contacts'))
username_changed_at TIMESTAMPTZ

-- Yeni tablo:
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);
```

### Yeni/Güncellenen Dosyalar:
- `lib/shared/story_service.dart` - Story yönetimi servisi (YENİ)
- `lib/features/story/story_create_page.dart` - StoryService entegrasyonu
- `lib/features/story/story_viewer_page.dart` - Gerçek story gösterimi
- `lib/features/chats/chats_page.dart` - Story UI güncellemesi
- `lib/features/chats/forward_message_page.dart` - Mock kaldırıldı

### Veritabanı Değişiklikleri:
```sql
-- stories tablosuna eklenen alan:
metadata JSONB  -- Metin story özellikleri (gradient, fontSize, vb.)
```

---

## 📝 Son Değişiklikler (28 Aralık 2024 - Mock Temizliği)

### 🧹 Kapsamlı Mock/Demo Veri Temizliği

Tüm faz 1-5 için mock ve demo verileri temizlendi, gerçek Supabase entegrasyonu yapıldı:

#### Model Güncellemeleri:
- ✅ `ChatPreview`: `isGroup`, `avatarUrl` alanları eklendi
- ✅ `MessageAdapter`: Medya alanları (type, mediaUrl, metadata) Hive'a eklendi
- ✅ `ChatPreviewAdapter`: Yeni alanlarla güncellendi

#### Temizlenen Mock Veriler:
| Dosya | Eski Durum | Yeni Durum |
|-------|------------|------------|
| `ChatStore` | Mock chat listesi | Sadece Supabase |
| `ChatsPage` | Gruplar filtresi boş | `isGroup` ile gerçek filtreleme |
| `QRScannerPage` | Test demo butonu | Kaldırıldı |
| `UserProfilePage` | Mock ortak gruplar | `ChatService.getCommonGroups()` |
| `MediaGalleryPage` | Mock fotoğraf/video | `ChatService.getChatMedia()` |
| `StarredMessagesPage` | Mock yıldızlı mesajlar | Boş (DB desteği bekliyor) |
| `BroadcastListPage` | Mock kişi listesi | `ContactService.contacts` |
| `MessageInfoSheet` | Mock teslim/okunma zamanları | `ChatService.getMessageStatus()` |

#### Yeni ChatService Metodları:
- `getCommonGroups(userId)` - İki kullanıcı arasındaki ortak grupları getir
- `getChatMedia(chatId)` - Sohbetteki medya mesajlarını getir
- `getMessageStatus(messageId)` - Mesaj teslim/okunma zamanlarını getir

#### Güncellenen Dosyalar:
- `lib/shared/models.dart` - ChatPreview genişletildi
- `lib/shared/hive_adapters.dart` - MessageAdapter, ChatPreviewAdapter güncellendi
- `lib/shared/chat_store.dart` - Mock veri kaldırıldı, Supabase entegrasyonu
- `lib/shared/chat_service.dart` - Yeni metodlar eklendi
- `lib/shared/story_service.dart` - Story yanıtlama ChatService entegrasyonu
- `lib/shared/widgets/qr_code.dart` - Demo button kaldırıldı
- `lib/features/chats/chats_page.dart` - Grup filtreleme düzeltildi
- `lib/features/profile/user_profile_page.dart` - Ortak gruplar Supabase'den
- `lib/features/chats/media_gallery_page.dart` - Medya Supabase'den
- `lib/features/chats/chat_extras_pages.dart` - StarredMessages hazırlandı
- `lib/features/chats/broadcast_list_page.dart` - Kişiler ContactService'den
- `lib/features/chat_detail/message_info_sheet.dart` - Gerçek teslim zamanları

### ⚠️ Bekleyen Backend Özellikleri:
- `StarredMessagesPage`: Database'de `is_starred` field gerekli
- `LinkedDevicesPage`: Faz 7/8'de yapılacak
- `CallsPage`: Faz 6'da yapılacak
