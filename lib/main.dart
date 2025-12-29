import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'app/app_settings.dart';
import 'shared/accessibility.dart';
import 'shared/app_lock_service.dart';
import 'shared/chat_service.dart';
import 'shared/chat_store.dart';
import 'shared/contact_service.dart';
import 'shared/hive_adapters.dart';
import 'shared/network_service.dart';
import 'shared/settings_service.dart';
import 'shared/story_service.dart';
import 'shared/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase'i başlat
  await SupabaseService.instance.init();
  
  // Hive başlat
  await Hive.initFlutter();
  
  // Hive adapter'larını kaydet
  await HiveBoxes.registerAdapters();
  
  // Eski cache'i temizle (v2 format geçişi)
  await HiveBoxes.clearOldCache();
  
  // Kutuları aç
  await HiveBoxes.openBoxes();
  
  // Ayarları yükle
  await AppSettings.instance.init();
  
  // Settings service'i başlat (bildirim ve sohbet ayarları)
  await SettingsService.instance.init();
  
  // Erişilebilirlik ayarlarını yükle
  await AccessibilitySettings.instance.init();
  
  // Chat store'u başlat
  await ChatStore.instance.init();
  
  // Contact service'i başlat (2.4, 2.5, 2.6)
  await ContactService.instance.init();
  
  // Story service'i başlat ve story'leri yükle (5.1, 5.2, 5.3)
  await StoryService.instance.loadStories();
  
  // Uygulama kilidi servisini başlat
  await AppLockService.instance.init();
  
  // Ağ durumu servisini başlat
  await NetworkService.instance.init();
  
  runApp(const NearApp());
}

/// Uygulama yaşam döngüsü observer'ı - online durumu yönetir
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final chatService = ChatService.instance;
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Uygulama öne geldi - online ol
        chatService.setOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Uygulama arka plana geçti - offline ol
        chatService.setOnlineStatus(false);
        break;
    }
  }
}
