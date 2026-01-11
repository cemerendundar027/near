# Near - Product Requirements Document (PRD)

> **Near** - Modern, WhatsApp tarzı tasarıma sahip Flutter tabanlı mesajlaşma uygulaması
>
> **Versiyon:** 1.0.0 (Release Hazırlığında)  
> **Platform:** iOS, Android, Web, macOS, Linux, Windows  
> **SDK:** Flutter ^3.10.4  
> **Backend:** Supabase (PostgreSQL + Realtime + Storage + Auth)  
> **Tema:** NearTheme (Primary: #7B3FF2 Eflatun)  
> **Son Güncelleme:** 11 Ocak 2026

---

## 🎯 v1.0 RELEASE STATUS

| Faz | Adı | Durum | v1.0 Gerekli | Tarih |
|-----|-----|-------|-------------|-------|
| 0 | Temel Altyapı | ✅ | Evet | 16.12.2024 |
| 1 | Temel Mesajlaşma | ✅ | Evet | 16.12.2024 |
| 2 | Profil & Kişiler | ✅ | Evet | 27.12.2024 |
| 3 | Grup Sohbetleri | ✅ | Evet | 23.12.2024 |
| 4 | Medya Paylaşımı | ✅ | Evet | 25.12.2024 |
| 5 | Story Sistemi | ✅ | Evet | 28.12.2024 |
| 6 | Sesli/Görüntülü Arama (1-1) | 🔄 | **Evet** | Backend: 11.01.2026 |
| 7 | Push Notifications | ⬜ | **Evet** | - |
| 8 | Temel Güvenlik | ⬜ | **Evet** | - |
| 9 | Grup Araması (SFU) | ⬜ | Hayır (v1.1+) | - |
| 10 | Offline & Sync | ⬜ | Hayır (v1.1+) | - |
| 11 | Deployment | ⬜ | **Evet** | - |

**v1.0 için Tamamlanması Gereken:** Faz 6, 7, 8, 11  
**Tahmini Süre:** 3-4 hafta

---

## ✅ TAMAMLANAN FAZLAR (Faz 0-5)

### ✅ Faz 0: Temel Altyapı (16 Aralık 2024)
- [x] **Database:** 10 tablo + RLS policies
- [x] **Supabase Auth:** Email/Password + OTP SMS
- [x] **Services:** ChatService, AuthService, ContactService, StoryService (60+ metodlar)
- [x] **Frontend:** 165+ özellik + Material Design 3
- [x] **Realtime:** Supabase Realtime subscription aktif

### ✅ Faz 1: Temel Mesajlaşma (16 Aralık 2024)
- [x] 1-1 sohbet oluşturma (createDirectChat, findExistingDirectChat)
- [x] Mesaj gönderme (sendMessage + Storage medya)
- [x] Gerçek zamanlı mesaj alma (subscribeToMessages + Realtime)
- [x] Mesaj durumu tracking (sent/delivered/read)
- [x] Yazıyor göstergesi (subscribeToTyping + sendTypingIndicator)
- [x] Online/Offline durumu (setOnlineStatus + 30 saniye heartbeat)

### ✅ Faz 2: Profil & Kişiler (27 Aralık 2024)
- [x] Profil güncelleme (ad, biyografi, telefon, avatar)
- [x] Avatar yükleme (Supabase Storage)
- [x] Username sistemi (benzersiz, 90 gün değişim kuralı)
- [x] Kullanıcı arama (searchUsers, getAllUsers)
- [x] Kişi yönetimi (ContactService: add/remove/block)
- [x] Engelleme sistemi (blockUser, unblockUser, BlockedUsersPage)
- [x] Gizlilik ayarları (last_seen, profile_photo, about, read_receipts, messages)
- [x] QR ile kişi ekleme (MyQRCodePage, QRScannerPage - mobile_scanner)

### ✅ Faz 3: Grup Sohbetleri (23 Aralık 2024)
- [x] Grup oluşturma (createGroupChat: name, avatar, members)
- [x] Üye yönetimi (addMembersToGroup, removeMemberFromGroup)
- [x] Admin kontrolü (makeUserAdmin, removeUserAdmin, getUserRoleInGroup)
- [x] Grup düzenleme (updateGroupName, updateGroupAvatar)
- [x] @Mention sistemi (parseMentions, sendMessageWithMentions)
- [x] Gruptan ayrılma (leaveGroup)
- [x] Grup bilgisi (getGroupInfo, getGroupMembers)

### ✅ Faz 4: Medya Paylaşımı (24-25 Aralık 2024)
- [x] Fotoğraf gönderme (ImagePicker, sıkıştırma, Supabase Storage)
- [x] Video gönderme (thumbnail oluşturma, max 100MB)
- [x] Sesli mesaj (AudioService + record paketi - WAV)
- [x] Dosya gönderme (file_picker, tüm dosya tipleri)
- [x] GIF arama ve gönderme (Tenor API entegrasyonu)
- [x] Konum paylaşımı (geolocator + geocoding)
- [x] Kişi paylaşımı (flutter_contacts)
- [x] Medya sıkıştırma ve önizleme
- [x] Medya galerisi (MediaGalleryPage - getChatMedia)
- [x] Emoji picker (tam emoji desteği)

### ✅ Faz 5: Story Sistemi (28 Aralık 2024)
- [x] Story oluşturma (StoryService.createStory - fotoğraf + metin)
- [x] Story görüntüleme (StoryViewerPage + Supabase veri)
- [x] Görüntüleyenleri takip (story_views tablosu + UI)
- [x] Story silme (deleteStory + Storage cleanup)
- [x] 24 saat expiry (expires_at filtresi + Supabase triggers)
- [x] Story yanıtlama (DM reply desteği)
- [x] Story metadata (gradient, fontSize, alignment - JSONB)

---

## ✨ YENI ÖZELLİKLER (Faz 1-5)

### UX Özellikleri ✅
- **Swipe to Reply:** Mesaja sağa/sola kaydırarak yanıtla
- **Double-Tap Like:** Çift tıkla kalp ❤️ reaksiyonu (animasyonlu)
- **Emoji Reactions:** Mesajlara emoji tepki menüsü (❤️ 👍 😂 😮 😢 🙏)
- **App Lock:** PIN + Face ID / Touch ID + timeout ayarı

### Kullanıcı Yönetimi ✅
- **Username Sistemi:** Benzersiz, 90 gün değişim kuralı
- **Username Arama:** Kullanıcı adı ile kullanıcı bulma
- **Privacy Settings:** Last_seen, profile_photo, about, read_receipts
- **Message Privacy:** Sadece rehberdekiler / herkes mesaj gönderebilir
- **Blocking:** Kullanıcı engelleme ve engellenenler listesi

### Medya & İçerik ✅
- **Medya Galerisi:** Sohbet medyaları (getChatMedia)
- **GIF Arama:** Tenor API ile GIF arama ve gönderme
- **Konum:** GPS + Geocoding ile adres paylaşımı
- **Kişi Paylaşımı:** Rehberden kişi seçip gönderme
- **Sesli Mesaj:** Record + Just Audio ile ses kaydı/oynatma

---

## ⬜ YAPILACAK FAZLAR

### Faz 6: Sesli/Görüntülü Arama - 1-1 (2-3 hafta)
**Hedef:** WebRTC ile gerçek zamanlı P2P arama (1-1 sadece)  
**Gerekli Paketler:** `flutter_webrtc`, `flutter_callkit_incoming`  
**Backend Durumu:** ✅ Supabase şeması hazır (11 Ocak 2026)  
**Not:** Grup araması v1.1+ olarak planlanmıştır (SFU backend gerekir)

| # | Görev | Durum | Not |
|---|-------|-------|-----|
| 6.0 | Supabase şeması | ✅ | calls tablosu güncellendi, ice_candidates oluşturuldu |
| 6.1 | flutter_webrtc paketi | ⬜ | WebRTC P2P implementasyonu |
| 6.2 | WebRTC signaling | ⬜ | Supabase Realtime kullanılacak |
| 6.3 | Sesli arama (1-1) | ⬜ | Audio stream, P2P direkt bağlantı |
| 6.4 | Görüntülü arama (1-1) | ⬜ | Video stream + UI, P2P direkt bağlantı |
| 6.5 | CallKit (iOS) | ⬜ | Native arama UI entegrasyonu |
| 6.6 | ConnectionService (Android) | ⬜ | Native arama UI entegrasyonu |
| 6.7 | Arama geçmişi | ⬜ | calls tablosu hazır |

**Backend (Tamamlandı):**
- `calls` tablosu: callee_id, offer_sdp, answer_sdp, ringing_at, accepted_at, connected_at, end_reason, quality_score, metadata
- `ice_candidates` tablosu: call_id, sender_id, candidate, sdp_mid, sdp_m_line_index, processed
- RLS policies: Kullanıcı sadece kendi aramalarını görebilir/güncelleyebilir
- Realtime: calls ve ice_candidates tabloları için aktif
- Helper functions: is_user_in_call(), calculate_call_duration() trigger |

### Faz 7: Push Notifications & Firebase (1 hafta)
**Hedef:** Uygulama kapalıyken bildirim  
**Gerekli Paketler:** `firebase_core`, `firebase_messaging`, `firebase_crashlytics`, `firebase_analytics`

| # | Görev | Durum | Not |
|---|-------|-------|-----|
| 7.1 | Firebase projesi | ⬜ | console.firebase.google.com |
| 7.2 | FCM (Android) | ⬜ | google-services.json |
| 7.3 | APNs (iOS) | ⬜ | APNs key + GoogleService-Info.plist |
| 7.4 | Push token | ⬜ | push_tokens tablosu hazır |
| 7.5 | Mesaj bildirimi | ⬜ | Supabase Edge Function |
| 7.6 | Arama bildirimi | ⬜ | VoIP push |
| 7.7 | Crashlytics | ⬜ | Hata takibi |
| 7.8 | Analytics | ⬜ | Kullanım istatistikleri |

### Faz 8: Temel Güvenlik (3-4 gün)
**Hedef:** Temel güvenlik uygulaması  
**Gerekli Paketler:** `flutter_secure_storage`

| # | Görev | Durum | Not |
|---|-------|-------|-----|
| 8.1 | SSL Pinning | ⬜ | MITM koruması |
| 8.2 | Secure Storage | ⬜ | Token ve sensitive data |
| 8.3 | Input validation | ⬜ | XSS/Injection koruması |
| 8.4 | Rate limiting | ⬜ | Supabase RLS + Edge Functions |
| 8.5 | Biometric lock | ✅ | LocalAuth aktif (Faz 5) |
| 8.6 | Session management | ⬜ | Token refresh, auto-logout |

**Not:** E2E encryption (Signal protokolü) v2.0 için planlanmış

### Faz 9: Grup Araması (v1.1+, 2-3 hafta)
**Hedef:** SFU (Selective Forwarding Unit) kullanarak grup sesli/görüntülü arama  
**Gerekli Paketler:** `flutter_webrtc`, `mediasoup-client` veya özel SFU backend  
**Teknik:** P2P mesh yerine merkezi SFU sunucusu (CPU/bandwidth optimizasyon)

| # | Görev | Durum | Not |
|---|-------|-------|-----|
| 9.1 | SFU backend kurulumu | ⬜ | Mediasoup, Jitsi veya özel |
| 9.2 | Group signaling | ⬜ | Supabase + custom WebSocket |
| 9.3 | Grup sesli arama | ⬜ | Audio streams merging |
| 9.4 | Grup görüntülü arama | ⬜ | Video grid + pip |
| 9.5 | Screen sharing | ⬜ | Desktop/tablet desteği |
| 9.6 | Recording (opsiyonel) | ⬜ | Arama kaydı |

### Faz 10: Offline & Sync (v1.1+)
**Not:** v1.0'da temel Hive cache mevcut

| # | Görev | Durum | Not |
|---|-------|-------|-----|
| 10.1 | Local DB | 🔄 | Hive kurulu (basic cache) |
| 10.2 | Offline mesaj kuyruğu | ⬜ | Retry mekanizması |
| 10.3 | Sync mekanizması | ⬜ | Conflict resolution |
| 10.4 | Chat backup | ⬜ | Export/Import |
| 10.5 | Chat restore | ⬜ | Cloud backup |

### Faz 11: Deployment (v1.0, 1-2 hafta)

#### 11.A - Yasal & Marka
| # | Görev | Durum |
|---|-------|-------|
| 11.A.1 | Privacy Policy | ⬜ |
| 11.A.2 | Terms of Service | ⬜ |
| 11.A.3 | App Icon | ⬜ |
| 11.A.4 | Splash Screen | ⬜ |
| 11.A.5 | Store Graphics | ⬜ |
| 11.A.6 | App Description | ⬜ |

#### 11.B - Konfigürasyon
| # | Görev | Durum |
|---|-------|-------|
| 11.B.1 | Environment variables | ⬜ |
| 11.B.2 | Production Supabase | ⬜ |
| 11.B.3 | Bundle ID/Package name | ⬜ |
| 11.B.4 | App versioning | ⬜ |
| 11.B.5 | ProGuard/R8 (Android) | ⬜ |

#### 11.C - iOS Deployment
| # | Görev | Durum |
|---|-------|-------|
| 11.C.1 | Apple Developer hesabı | ⬜ |
| 11.C.2 | App Store Connect | ⬜ |
| 11.C.3 | Certificates & Profiles | ⬜ |
| 11.C.4 | TestFlight beta | ⬜ |
| 11.C.5 | App Store review | ⬜ |

#### 11.D - Android Deployment
| # | Görev | Durum |
|---|-------|-------|
| 11.D.1 | Google Play Console | ⬜ |
| 11.D.2 | Signing key | ⬜ |
| 11.D.3 | App Bundle (AAB) | ⬜ |
| 11.D.4 | Internal testing | ⬜ |
| 11.D.5 | Play Store review | ⬜ |

#### 11.E - Test & Monitoring
| # | Görev | Durum |
|---|-------|-------|
| 11.E.1 | Unit tests | ⬜ |
| 11.E.2 | Widget tests | ⬜ |
| 11.E.3 | Integration tests | ⬜ |
| 11.E.4 | CI/CD pipeline | ⬜ |
| 11.E.5 | Crash reporting | ✅ |
| 11.E.6 | Performance monitoring | ⬜ |

---

## 📊 BACKEND DURUMU

### Supabase Konfigürasyonu
- **URL:** https://uskgzwhhopfwklwcqjaj.supabase.co
- **Bölge:** EU (Frankfurt)
- **Auth:** Email/Password + OTP SMS ✅
- **Database:** 10 tablo + RLS policies ✅
- **Realtime:** Mesaj, typing, online status ✅
- **Storage:** avatars, media, stories buckets (manuel oluşturulacak)

### Database Tabloları (12/12) ✅
| Tablo | Durum | Açıklama |
|-------|-------|----------|
| `profiles` | ✅ | Kullanıcı profilleri, username, privacy settings |
| `chats` | ✅ | Sohbetler (1-1 ve grup), metadata |
| `chat_participants` | ✅ | Sohbet üyeleri, role (admin/member) |
| `messages` | ✅ | Mesajlar, type, content, media, reply, mention |
| `message_status` | ✅ | delivered_at, read_at tracking |
| `message_reactions` | ✅ | Emoji reaksiyonları (❤️ 👍 😂 😮 😢 🙏) |
| `contacts` | ✅ | Kişi listesi, blocked users |
| `stories` | ✅ | 24 saat hikayeler, metadata (gradient, font) |
| `story_views` | ✅ | Story görüntüleyenler ve zamanları |
| `calls` | ✅ | Arama kayıtları + WebRTC SDP (Faz 6 backend hazır) |
| `ice_candidates` | ✅ | WebRTC ICE adayları (Faz 6 backend hazır) |
| `push_tokens` | ⬜ | FCM/APNs token'ları (Faz 7) |

### Storage Buckets (Manuel Oluşturulacak)
- **avatars** - Profil fotoğrafları
- **media** - Sohbet medyaları (resim, video, ses, dosya)
- **stories** - Story medyaları (24h auto-delete)

### Realtime Channels
| Channel | Event | Kullanım |
|---------|-------|----------|
| `messages:chat_id` | INSERT, UPDATE | Mesaj güncellemeleri |
| `typing:chat_id` | Broadcast | Yazıyor göstergesi |
| `presence` | Track | Online/offline durumu |
| `chats:user_id` | INSERT, UPDATE | Sohbet listesi güncellemeleri |

---

## 🏗️ MİMARİ & SERVİSLER

### Veri Akışı
```
UI (Pages/Widgets)
       ↓↑
State Management (ChatStore, Provider)
       ↓↑
Service Layer (ChatService, AuthService, ContactService, StoryService)
       ↓↑
Supabase Client
       ↓↑
Supabase Backend (PostgreSQL + Realtime + Storage + Auth)
```

### Temel Servisler

#### ChatService (35+ metodlar)
**Mesajlaşma:**
- `sendMessage()` - Mesaj gönderme (metin, medya, GIF, konum, kişi)
- `subscribeToMessages()` - Realtime mesaj alma
- `markMessageAsDelivered()` / `markMessageAsRead()` - Mesaj durumu
- `deleteMessage()` / `editMessage()` - Mesaj düzenle/sil
- `addReaction()` / `getMessageReactions()` - Emoji reaksiyonları
- `getMessageStatus()` - Teslim/okunma zamanları

**Sohbet:**
- `createDirectChat()` - 1-1 sohbet oluşturma
- `createGroupChat()` - Grup sohbeti oluşturma
- `loadChats()` - Sohbet listesini yükleme
- `getGroupInfo()` - Grup detaylarını getirme
- `getGroupMembers()` - Üyeleri listeleme
- `getChatMedia()` - Sohbet medyaları
- `getCommonGroups()` - Ortak gruplar

**Grup Yönetimi:**
- `addMembersToGroup()` - Üye ekleme
- `removeMemberFromGroup()` - Üye çıkarma
- `makeUserAdmin()` / `removeUserAdmin()` - Admin kontrolü
- `updateGroupName()` / `updateGroupAvatar()` - Grup düzenleme
- `leaveGroup()` - Gruptan ayrılma
- `getUserRoleInGroup()` - Kullanıcı rolü

**Realtime & Durum:**
- `setOnlineStatus()` - Online/offline durumu (30s heartbeat)
- `subscribeToTyping()` - Yazıyor göstergesi dinleme
- `sendTypingIndicator()` - Yazıyor bildirimi
- `parseMentions()` - @mention işleme

**Arama:**
- `searchUsers()` - Kullanıcı arama (query)
- `getAllUsers()` - Tüm kullanıcılar listesi

#### ContactService (10+ metodlar)
- `addContact()` / `removeContact()` - Kişi ekleme/çıkarma
- `blockUser()` / `unblockUser()` - Kullanıcı engelleme
- `getBlockedUsers()` - Engellenenler listesi
- `updatePrivacySettings()` - Gizlilik ayarları
- `checkPrivacyAllowsMessaging()` - Mesaj gönderme izni kontrolü

#### AuthService (10+ metodlar)
- `sendOTP()` - SMS OTP gönderme
- `verifyOTP()` - OTP doğrulama
- `signUpEmail()` - Email ile kayıt
- `signInEmail()` - Email ile giriş
- `signOut()` - Çıkış yapma
- `updateProfile()` - Profil güncelleme
- `uploadAvatar()` - Avatar yükleme

#### StoryService (6+ metodlar)
- `createStory()` - Story oluşturma (fotoğraf/metin + metadata)
- `deleteStory()` - Story silme + Storage cleanup
- `getStoriesForUser()` - Kullanıcı story'leri
- `getContactsStories()` - Kişilerin story'leri
- `markStoryAsViewed()` - Story görüntüleme kaydı
- `getStoryViewers()` - Story görüntüleyenleri

#### AppLockService
- `setPIN()` - PIN ayarlama
- `verifyPIN()` - PIN doğrulama
- `authenticateBiometric()` - Face ID / Touch ID
- `setLockTimeout()` - Otomatik kilit süresi

#### AudioService
- `startRecording()` - Ses kaydı başlatma
- `stopRecording()` - Ses kaydı durdurma
- `playAudio()` - Ses dosyası oynatma
- `pauseAudio()` - Ses oynatmayı duraklat

### State Management
- **ChatStore:** Sohbet listesi, seçili sohbet, mesaj cache
- **Provider:** Kullanıcı profili, ayarlar, tema
- **Hive:** Local cache (offline önbellek)

---

## 📁 PROJE YAPISI

```
near/
├── lib/
│   ├── main.dart                      # Uygulama giriş noktası
│   ├── app/
│   │   ├── app.dart                   # MaterialApp + GoRouter
│   │   ├── app_settings.dart          # Ayarlar (tema, font, wallpaper)
│   │   ├── root_tabs.dart             # Ana tab bar navigasyonu
│   │   ├── theme.dart                 # NearTheme (renk paleti)
│   │   └── lock_screen.dart           # App Lock UI
│   ├── config/
│   │   └── supabase_config.dart       # Supabase URL & API key
│   ├── features/
│   │   ├── auth/
│   │   │   ├── auth_page.dart         # Telefon doğrulama
│   │   │   └── otp_page.dart          # OTP giriş
│   │   ├── calls/
│   │   │   ├── calls_page.dart        # Arama geçmişi (Faz 6)
│   │   │   └── call_screen.dart       # Aktif arama ekranı (Faz 6)
│   │   ├── chat_detail/
│   │   │   ├── chat_detail_page.dart  # Sohbet detay sayfası
│   │   │   ├── message_info_sheet.dart # Mesaj bilgi modalı
│   │   │   └── ...                    # Diğer chat widget'ları
│   │   ├── chats/
│   │   │   ├── chats_page.dart        # Ana sohbet listesi
│   │   │   ├── new_chat_page.dart     # Yeni sohbet oluştur
│   │   │   ├── new_group_page.dart    # Yeni grup oluştur
│   │   │   ├── media_gallery_page.dart # Medya galerisi
│   │   │   ├── forward_message_page.dart # Mesaj iletme
│   │   │   ├── broadcast_list_page.dart # Toplu mesaj
│   │   │   └── chat_extras_pages.dart  # Starred, Archived
│   │   ├── onboarding/
│   │   │   └── onboarding_page.dart   # İlk kullanım rehberi
│   │   ├── profile/
│   │   │   ├── profile_edit_page.dart # Profil düzenleme
│   │   │   ├── user_profile_page.dart # Kullanıcı profili
│   │   │   ├── my_qr_code_page.dart   # QR kod göster
│   │   │   └── qr_scanner_page.dart   # QR kod okut
│   │   ├── settings/
│   │   │   ├── settings_page.dart     # Ana ayarlar
│   │   │   ├── account_page.dart      # Hesap ayarları
│   │   │   ├── privacy_page.dart      # Gizlilik ayarları
│   │   │   ├── chats_page.dart        # Sohbet ayarları
│   │   │   ├── notifications_page.dart # Bildirim ayarları
│   │   │   ├── storage_page.dart      # Depolama ayarları
│   │   │   ├── app_lock_page.dart     # Uygulama kilidi
│   │   │   └── blocked_users_page.dart # Engellenenler
│   │   ├── splash/
│   │   │   └── splash_page.dart       # Açılış ekranı
│   │   └── story/
│   │       ├── story_viewer_page.dart # Story görüntüleyici
│   │       └── story_create_page.dart # Story oluşturma
│   └── shared/
│       ├── supabase_service.dart      # ⭐ Supabase client
│       ├── auth_service.dart          # ⭐ Auth servisi
│       ├── chat_service.dart          # ⭐ Chat servisi (35+ metodlar)
│       ├── contact_service.dart       # ⭐ Contact servisi
│       ├── story_service.dart         # ⭐ Story servisi
│       ├── app_lock_service.dart      # ⭐ App Lock servisi
│       ├── audio_service.dart         # ⭐ Ses kaydı/oynatma
│       ├── network_service.dart       # Ağ durumu
│       ├── chat_store.dart            # State management
│       ├── message_store.dart         # Mesaj state
│       ├── models.dart                # Veri modelleri
│       ├── hive_adapters.dart         # Hive type adapters
│       └── widgets/                   # 28+ özel widget
│           ├── message_bubble.dart
│           ├── chat_tile.dart
│           ├── story_circle.dart
│           └── ...
├── supabase/
│   ├── schema.sql                     # Database şeması
│   ├── add_metadata_column.sql        # Story metadata migration
│   └── migrations/                    # SQL migrations
├── assets/
│   └── images/                        # Uygulama görselleri
├── android/                           # Android native code
├── ios/                               # iOS native code
├── pubspec.yaml                       # Flutter bağımlılıkları
└── prd.md                             # Bu dosya
```

---

## 🎨 TASARIM SİSTEMİ

### Renk Paleti (NearTheme)
| Renk | Hex | Kullanım |
|------|-----|----------|
| **Primary** | `#7B3FF2` | Ana eflatun rengi |
| **PrimaryDark** | `#5A22C8` | Koyu eflatun (vurgu) |
| **PrimarySoft** | `#E9DEFF` | Açık eflatun (arka plan) |
| **MyBubble** | `#6C2FEA` | Gönderilen mesaj baloncuğu |
| **TheirBubble** | `#E6DAFF` | Alınan mesaj baloncuğu (light) |
| **TheirBubbleDark** | `#2D2D2D` | Alınan mesaj (dark mode) |
| **Online** | `#25D366` | Çevrimiçi göstergesi |
| **Typing** | `#FFA500` | Yazıyor göstergesi |

### Tipografi
- **Font Family:** Google Fonts (Inter, Roboto)
- **Heading:** Bold, 20-24px
- **Body:** Regular, 14-16px
- **Caption:** Regular, 12px

### İkonlar
- Material Icons (default)
- Cupertino Icons (iOS native feel)

### Animasyonlar
- Lottie animations (splash, loading)
- Hero transitions (profil, medya)
- Swipe gestures (reply, delete)

---

## 📦 BAĞIMLILIKLAR (pubspec.yaml)

### Core & Backend
- `flutter` - Flutter SDK
- `cupertino_icons` - iOS icons
- `supabase_flutter: ^2.0.0` - Backend servisleri

### State & Storage
- `hive: ^2.2.3` - Local database
- `hive_flutter: ^1.1.0` - Flutter Hive entegrasyonu
- `shared_preferences: ^2.2.2` - Key-value storage

### UI & Navigation
- `go_router: ^13.0.0` - Routing & deep linking
- `google_fonts: ^6.1.0` - Custom fonts
- `lottie: ^3.0.0` - Animasyonlar
- `cached_network_image: ^3.3.1` - Image caching

### Media & Camera
- `image_picker: ^1.0.7` - Fotoğraf/video seçme
- `video_player: ^2.8.2` - Video oynatma
- `record: ^5.0.4` - Ses kaydı
- `just_audio: ^0.9.36` - Ses oynatma
- `file_picker: ^6.1.1` - Dosya seçme
- `flutter_contacts: ^1.1.7` - Rehber erişimi
- `mobile_scanner: ^3.5.6` - QR kod tarama

### Location & Maps
- `geolocator: ^11.0.0` - GPS konum
- `geocoding: ^2.1.1` - Adres çözümleme

### Sharing & Communication
- `url_launcher: ^6.2.4` - Link açma
- `share_plus: ^7.2.1` - Paylaşma
- `permission_handler: ^11.2.0` - İzin yönetimi

### Security & Auth
- `local_auth: ^2.1.8` - Biometric auth (Face ID, Touch ID)
- `connectivity_plus: ^5.0.2` - Ağ durumu

### Utilities
- `http: ^1.2.0` - HTTP requests (Tenor GIF API)
- `intl: ^0.19.0` - Internationalization
- `path_provider: ^2.1.2` - Dosya yolları

### Dev Dependencies
- `build_runner: ^2.4.8` - Code generation
- `hive_generator: ^2.0.1` - Hive type adapters

---

## � GELİŞTİRİCİ NOTLARI

### Ortam Bilgisi
- **Flutter:** ^3.10.4
- **Dart:** Stable (latest)
- **Target:** iOS 12+, Android 6.0+ (API 23+), Web, Desktop
- **State Management:** ChangeNotifier + Provider
- **Network:** Supabase Realtime + REST API

### Supabase Konfigürasyonu
```dart
Project: Near Messaging App
URL: https://uskgzwhhopfwklwcqjaj.supabase.co
Region: EU (Frankfurt)
Auth: Email/Password + OTP SMS
Anon Key: (config dosyasında)
```

### Temel Kullanım Örnekleri

#### Mesaj Gönderme
```dart
// ChatService singleton erişimi
final chatService = ChatService.instance;

// Metin mesajı gönderme
await chatService.sendMessage(
  chatId: 'chat-uuid',
  content: 'Merhaba!',
  type: 'text',
);

// Medya mesajı gönderme
await chatService.sendMessage(
  chatId: 'chat-uuid',
  content: '',
  type: 'photo',
  mediaUrl: 'https://supabase.co/storage/...',
  metadata: {'width': 1920, 'height': 1080},
);
```

#### Realtime Dinleme
```dart
// Mesajları dinleme
chatService.subscribeToMessages(chatId).on('*', (payload) {
  final newMessage = Message.fromJson(payload['new']);
  print('Yeni mesaj: ${newMessage.content}');
});

// Typing göstergesi dinleme
chatService.subscribeToTyping(chatId, (typingUsers) {
  print('Yazanlar: ${typingUsers.join(", ")}');
});

// Typing bildirimi gönderme
await chatService.sendTypingIndicator(chatId, isTyping: true);
```

#### Online Durumu
```dart
// Online olarak işaretle
await chatService.setOnlineStatus(true);

// Offline olarak işaretle (app kapatılırken)
await chatService.setOnlineStatus(false);
```

#### Sohbet Oluşturma
```dart
// 1-1 sohbet
final chatId = await chatService.createDirectChat('other-user-id');

// Grup sohbeti
final groupId = await chatService.createGroupChat(
  name: 'Proje Ekibi',
  members: ['user-1-id', 'user-2-id', 'user-3-id'],
  avatarUrl: 'https://...',
);
```

#### Story İşlemleri
```dart
final storyService = StoryService.instance;

// Story oluşturma
await storyService.createStory(
  mediaUrl: 'https://...',
  mediaType: 'image',
  metadata: {
    'gradientStart': '#FF6B6B',
    'gradientEnd': '#4ECDC4',
  },
);

// Story görüntüleme kaydı
await storyService.markStoryAsViewed('story-id');
```

### Hata Ayıklama
```dart
// Supabase hataları
try {
  await chatService.sendMessage(...);
} catch (e) {
  if (e is PostgrestException) {
    print('Database error: ${e.message}');
  } else if (e is AuthException) {
    print('Auth error: ${e.message}');
  }
}

// Network durumu kontrolü
final networkService = NetworkService.instance;
networkService.onConnectivityChanged.listen((isConnected) {
  print('Network: ${isConnected ? "Online" : "Offline"}');
});
```

### Mock Veri Temizliği (Tamamlandı)
Tüm faz 1-5 için mock ve demo verileri temizlendi:
- ✅ `ChatStore`: Mock chat listesi kaldırıldı
- ✅ `ChatsPage`: Grup filtreleme Supabase'den
- ✅ `QRScannerPage`: Test demo butonu kaldırıldı
- ✅ `UserProfilePage`: Ortak gruplar `getCommonGroups()`
- ✅ `MediaGalleryPage`: Medya `getChatMedia()`
- ✅ `MessageInfoSheet`: Gerçek teslim zamanları

### Bekleyen Backend Özellikleri
- ⬜ `StarredMessagesPage`: `is_starred` field gerekli
- ⬜ `LinkedDevicesPage`: Faz 7/8'de yapılacak
- ⬜ `CallsPage`: Faz 6'da yapılacak

---

## 📊 ÖZET

### ✅ Tamamlanan (Faz 0-5)
- **Frontend UI:** 165+ özellik, Material Design 3
- **Backend Services:** 60+ metodlar (Chat, Auth, Contact, Story)
- **Database:** 10 tablo + RLS policies
- **Realtime:** Mesaj, typing, online status
- **Auth:** Email/Password + OTP SMS
- **Medya:** Fotoğraf, video, ses, dosya, GIF, konum, kişi
- **Story:** 24h expiry, görüntüleyenler, yanıtlama
- **Grup:** Admin, @mention, üye yönetimi
- **UX:** Swipe reply, emoji reactions, app lock

### ⬜ Yapılacak (Faz 6-10)
1. **Faz 6:** Sesli/Görüntülü Arama (WebRTC, CallKit) - 2-3 hafta
2. **Faz 7:** Push Notifications (Firebase FCM/APNs) - 1 hafta
3. **Faz 8:** Temel Güvenlik (SSL Pinning, Secure Storage) - 3-4 gün
4. **Faz 10:** Deployment (Privacy Policy, App Store, Google Play) - 1-2 hafta

**v1.0 Release Tahmini:** 3-4 hafta

### 🟢 v1.1+ için
- Offline sync & backup
- E2E Encryption (Signal protokolü)
- Grup araması
- Kaybolan mesajlar

---

## 📝 SON DEĞİŞİKLİKLER

### 28 Aralık 2024 - Faz 5 Tamamlandı
- ✅ Story sistemi (StoryService)
- ✅ Swipe to Reply
- ✅ Double-Tap Like
- ✅ Emoji Reactions
- ✅ App Lock (PIN + Biometric)
- ✅ Username sistemi (90 gün kuralı)
- ✅ Mesaj gizliliği ayarı
- ✅ Mock veri temizliği

### Güncellenmiş Dosyalar (Son)
- `lib/shared/story_service.dart` - Story yönetimi
- `lib/shared/app_lock_service.dart` - Kilit servisi
- `lib/app/lock_screen.dart` - Kilit ekranı UI
- `lib/features/chat_detail/chat_detail_page.dart` - UX özellikleri
- `lib/features/settings/app_lock_page.dart` - Kilit ayarları
- `lib/features/settings/privacy_page.dart` - Gizlilik ayarları
- `lib/shared/models.dart` - Model güncellemeleri
- `lib/shared/hive_adapters.dart` - Adapter güncellemeleri

### Veritabanı Değişiklikleri
```sql
-- profiles tablosuna
ALTER TABLE profiles ADD COLUMN privacy_messages TEXT DEFAULT 'everyone';
ALTER TABLE profiles ADD COLUMN username_changed_at TIMESTAMPTZ;

-- stories tablosuna
ALTER TABLE stories ADD COLUMN metadata JSONB;

-- Yeni tablo
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, user_id, emoji)
);
```

---

> **Son Güncelleme:** 11 Ocak 2026  
> **Durum:** Faz 1-5 ✅ Tamamlandı | Faz 6-10 ⬜ Beklemede  
> **v1.0 ETA:** 3-4 hafta 🚀  
> **Near:** Modern, güvenli, kullanıcı dostu mesajlaşma deneyimi

### Ortam Bilgisi
- **Flutter:** ^3.10.4
- **Dart:** Stabilden en son
- **Target:** iOS 12+, Android 6.0+, Web, Desktop
- **State Management:** ChangeNotifier (ChatService, ContactService)
- **Network:** Supabase Realtime + REST

### Supabase Konfigürasyonu
```
Project: Near Messaging App
URL: https://uskgzwhhopfwklwcqjaj.supabase.co
Region: EU (Frankfurt)
Auth: Email/Password + OTP SMS
```

### Realtime Channels
```
messages:chat_id           → Mesaj güncellemeleri
typing:chat_id            → Yazıyor göstergesi
presence                  → Online/offline durumu
chats:user_id            → Sohbet listesi
```

### Temel Kullanım
```dart
// ChatService erişimi
final chatService = ChatService.instance;

// Mesaj gönderme
await chatService.sendMessage(
  chatId: 'xxx',
  content: 'Merhaba!',
  type: 'text',
);

// Realtime dinleme
chatService.subscribeToMessages(chatId).on('*', (payload) {
  print('Yeni mesaj: ${payload['new']}');
});

// Online durumu
chatService.setOnlineStatus(true);
```

---

## 📝 v1.0 Release Planı

### ✅ Tamamlanan (Faz 0-5):
1. [x] Temel altyapı (Supabase, Auth, Database)
2. [x] Temel mesajlaşma (1-1 sohbet, realtime)
3. [x] Profil & Kişiler (username, engelleme, QR)
4. [x] Grup sohbetleri (@mention, admin)
5. [x] Medya paylaşımı (Fotoğraf, video, ses, dosya, GIF, konum)
6. [x] Story sistemi (24h expiry, görüntüleyenler)

### ⬜ Yapılacak (Sırayla):

#### Faz 6: Sesli/Görüntülü Arama (2-3 hafta)
- flutter_webrtc paketi
- WebRTC signaling
- CallKit (iOS) + ConnectionService (Android)
- Arama geçmişi

#### Faz 7: Push Notifications (1 hafta)
- Firebase FCM/APNs
- Supabase Edge Function
- Crashlytics, Analytics

#### Faz 8: Temel Güvenlik (3-4 gün)
- flutter_secure_storage
- SSL Pinning, Input validation
- Session management

#### Faz 10: Deployment (1-2 hafta)
- Privacy Policy, Terms of Service
- App Store Connect, Google Play Console
- Store screenshots ve description
- TestFlight, Internal Testing

### 🟢 v1.1+ için:
- Offline sync & backup
- E2E Encryption (Signal protokolü)

---

> **Son Güncelleme:** 9 Ocak 2026  
> **Durum:** Aktif Geliştirme - Faz 1-5 ✅ Tamamlandı, Faz 6-10 ⬜ Beklemede  
> **Tahmini v1.0 Tamamlanması:** 3-4 hafta 🚀

---

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

## 📝 Geliştirme Tarihi

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
