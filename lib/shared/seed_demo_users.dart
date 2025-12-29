import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Demo kullanıcıları Supabase'e ekler
/// Bu fonksiyonu bir kere çalıştırın
Future<void> seedDemoUsers() async {
  final supabase = Supabase.instance.client;
  
  final demoUsers = [
    {
      'id': '11111111-1111-1111-1111-111111111111',
      'username': 'ahmet_yilmaz',
      'full_name': 'Ahmet Yılmaz',
      'bio': 'Flutter Developer 🚀',
      'is_online': true,
    },
    {
      'id': '22222222-2222-2222-2222-222222222222',
      'username': 'ayse_demir',
      'full_name': 'Ayşe Demir',
      'bio': 'UI/UX Designer ✨',
      'is_online': false,
    },
    {
      'id': '33333333-3333-3333-3333-333333333333',
      'username': 'mehmet_kaya',
      'full_name': 'Mehmet Kaya',
      'bio': 'Mobile Developer 📱',
      'is_online': true,
    },
    {
      'id': '44444444-4444-4444-4444-444444444444',
      'username': 'zeynep_ozturk',
      'full_name': 'Zeynep Öztürk',
      'bio': 'Product Manager 💡',
      'is_online': false,
    },
    {
      'id': '55555555-5555-5555-5555-555555555555',
      'username': 'can_arslan',
      'full_name': 'Can Arslan',
      'bio': 'Backend Developer ⚡',
      'is_online': true,
    },
  ];

  for (final user in demoUsers) {
    try {
      await supabase.from('profiles').upsert(user, onConflict: 'id');
      debugPrint('✅ Demo user added: ${user['username']}');
    } catch (e) {
      debugPrint('❌ Error adding ${user['username']}: $e');
    }
  }
  
  debugPrint('🎉 Demo users seeding completed!');
}
