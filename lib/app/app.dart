import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'root_tabs.dart';
import 'theme.dart';
import 'app_settings.dart';
import 'lock_screen.dart';

import '../features/chat_detail/chat_detail_page.dart';
import '../features/story/story_viewer_page.dart';
import '../features/calls/call_screen.dart';

import '../features/settings/account_page.dart';
import '../features/settings/privacy_page.dart';
import '../features/settings/chats_settings_page.dart';
import '../features/settings/notifications_page.dart';
import '../features/settings/storage_page.dart';
import '../features/settings/help_page.dart';
import '../features/settings/blocked_users_page.dart';
import '../features/settings/muted_users_page.dart';
import '../features/settings/app_lock_page.dart';

import '../features/profile/profile_edit_page.dart';
import '../features/chats/group_info_page.dart';
// user_profile_page, media_gallery_page, forward_message_page
// require constructor arguments and are navigated via Navigator.push

import '../features/splash/splash_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/auth/auth_page.dart';

import '../features/chats/create_group_select_members_page.dart';
import '../features/chats/new_chat_page.dart';
import '../features/chats/chat_extras_pages.dart';
import '../features/chats/search_contacts_pages.dart';

import '../features/story/story_create_page.dart';

import '../features/settings/linked_devices_page.dart';

import '../shared/widgets/qr_code.dart';

import '../shared/accessibility.dart';
import '../shared/network_service.dart';
import '../shared/incoming_call_handler.dart';
import '../main.dart'; // AppLifecycleObserver için

/// Deep Link URL Scheme: near://
/// Supported Routes:
///   near://chat/{chatId}?msg={messageId}
///   near://story/{userId}
///   near://call/{userId}?video={true|false}
///   near://profile/{userId}
///   near://settings
///   near://contacts

class NearApp extends StatefulWidget {
  const NearApp({super.key});

  @override
  State<NearApp> createState() => _NearAppState();
}

class _NearAppState extends State<NearApp> {
  late final GoRouter _router;
  late final AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    
    // Lifecycle observer'ı kaydet (online durumu için)
    _lifecycleObserver = AppLifecycleObserver();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    
    // Heartbeat'i başlat (uygulama açıldığında online ol)
    _lifecycleObserver.startHeartbeat();
    
    // NOT: Gelen arama callback'leri şimdilik devre dışı
    // _setupIncomingCallHandlers();
  }

  void _setupIncomingCallHandlers() {
    final callHandler = IncomingCallHandler.instance;
    
    // Gelen arama bildirimi kabul edildiğinde
    callHandler.onCallAccepted = (callId) {
      debugPrint('NearApp: Call accepted: $callId');
      // Sadece kullanıcı giriş yaptıysa ve ana ekrandaysa yönlendir
      final currentLocation = _router.routerDelegate.currentConfiguration.fullPath;
      if (currentLocation != '/splash' && 
          currentLocation != '/auth' && 
          currentLocation != '/onboarding') {
        _router.push('/call/$callId?video=false&incoming=true');
      }
    };
    
    // Gelen arama bildirimi reddedildiğinde
    callHandler.onCallRejected = (callId) {
      debugPrint('NearApp: Call rejected: $callId');
    };
    
    // Arama sonlandığında
    callHandler.onCallEnded = (callId) {
      debugPrint('NearApp: Call ended: $callId');
    };
  }

  @override
  void dispose() {
    _lifecycleObserver.stopHeartbeat();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/splash',
      debugLogDiagnostics: false,
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),

        // Onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),

        // Auth
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const AuthPage(),
        ),

        // Main app with tabs
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const RootTabs(),
          routes: [
            // Chat detail - supports deep link: near://chat/{chatId}
            GoRoute(
              path: 'chat/:chatId',
              name: 'chat',
              builder: (context, state) {
                final chatId = state.pathParameters['chatId'];
                final messageId = state.uri.queryParameters['msg'];
                return ChatDetailPage(
                  deepLinkChatId: chatId,
                  deepLinkMessageId: messageId,
                );
              },
            ),

            // Story viewer - supports deep link: near://story/{userId}
            GoRoute(
              path: 'story/:userId',
              name: 'story',
              builder: (context, state) {
                final userId = state.pathParameters['userId'];
                return StoryViewerPage(deepLinkUserId: userId);
              },
            ),

            // Call screen - supports deep link: near://call/{userId}?video=true
            GoRoute(
              path: 'call/:userId',
              name: 'call',
              builder: (context, state) {
                final userId = state.pathParameters['userId'];
                final isVideo =
                    state.uri.queryParameters['video'] == 'true';
                return CallScreen(
                  deepLinkUserId: userId,
                  isVideoCall: isVideo,
                );
              },
            ),

            // Settings routes
            GoRoute(
              path: 'settings',
              name: 'settings',
              builder: (context, state) => const RootTabs(initialTab: 3),
              routes: [
                GoRoute(
                  path: 'account',
                  name: 'account',
                  builder: (context, state) => const AccountPage(),
                ),
                GoRoute(
                  path: 'privacy',
                  name: 'privacy',
                  builder: (context, state) => const PrivacyPage(),
                ),
                GoRoute(
                  path: 'chats',
                  name: 'chats-settings',
                  builder: (context, state) => const ChatsSettingsPage(),
                ),
                GoRoute(
                  path: 'notifications',
                  name: 'notifications',
                  builder: (context, state) => const NotificationsPage(),
                ),
                GoRoute(
                  path: 'storage',
                  name: 'storage',
                  builder: (context, state) => const StoragePage(),
                ),
                GoRoute(
                  path: 'help',
                  name: 'help',
                  builder: (context, state) => const HelpPage(),
                ),
                GoRoute(
                  path: 'blocked',
                  name: 'blocked',
                  builder: (context, state) => const BlockedUsersPage(),
                ),
                GoRoute(
                  path: 'muted',
                  name: 'muted',
                  builder: (context, state) => const MutedUsersPage(),
                ),
                GoRoute(
                  path: 'devices',
                  name: 'linked-devices',
                  builder: (context, state) => const LinkedDevicesPage(),
                ),
                GoRoute(
                  path: 'app-lock',
                  name: 'app-lock',
                  builder: (context, state) => const AppLockSettingsPage(),
                ),
              ],
            ),

            // Profile
            GoRoute(
              path: 'profile/edit',
              name: 'profile-edit',
              builder: (context, state) => const ProfileEditPage(),
            ),

            // Chat features
            GoRoute(
              path: 'new-chat',
              name: 'new-chat',
              builder: (context, state) => const NewChatPage(),
            ),
            GoRoute(
              path: 'create-group',
              name: 'create-group',
              builder: (context, state) => const CreateGroupSelectMembersPage(),
            ),
            // Group info (3.1, 3.2, 3.3)
            GoRoute(
              path: 'group/:groupId',
              name: 'group-info',
              builder: (context, state) {
                final groupId = state.pathParameters['groupId'] ?? '';
                return GroupInfoPage(groupId: groupId);
              },
            ),
            GoRoute(
              path: 'starred',
              name: 'starred',
              builder: (context, state) => const StarredMessagesPage(),
            ),
            GoRoute(
              path: 'broadcasts',
              name: 'broadcasts',
              builder: (context, state) => const BroadcastListPage(),
            ),
            GoRoute(
              path: 'archived',
              name: 'archived',
              builder: (context, state) => const ArchivedChatsPage(),
            ),
            GoRoute(
              path: 'search',
              name: 'search',
              builder: (context, state) => const SearchPage(),
            ),
            GoRoute(
              path: 'contacts',
              name: 'contacts',
              builder: (context, state) => const ContactsPage(),
            ),

            // QR Code (2.7)
            GoRoute(
              path: 'qr-code',
              name: 'qr-code',
              builder: (context, state) => const MyQRCodePage(),
            ),
            GoRoute(
              path: 'qr-scanner',
              name: 'qr-scanner',
              builder: (context, state) => const QRScannerPage(),
            ),

            // Story
            GoRoute(
              path: 'create-story',
              name: 'create-story',
              builder: (context, state) => const StoryCreatePage(),
            ),
          ],
        ),
      ],
    );
  }

  ThemeMode _mapThemeMode(NearThemeMode m) {
    switch (m) {
      case NearThemeMode.system:
        return ThemeMode.system;
      case NearThemeMode.light:
        return ThemeMode.light;
      case NearThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final accessibilitySettings = AccessibilitySettings.instance;

    // Listen to both AppSettings and AccessibilitySettings
    return ListenableBuilder(
      listenable: Listenable.merge([settings, accessibilitySettings]),
      builder: (context, _) {
        // Get theme based on high contrast mode
        ThemeData lightTheme = NearTheme.light();
        ThemeData darkTheme = NearTheme.dark();

        // Apply high contrast if enabled
        if (accessibilitySettings.highContrastMode) {
          lightTheme = _applyHighContrast(lightTheme);
          darkTheme = _applyHighContrastDark(darkTheme);
        }

        // Apply bold text if enabled
        if (accessibilitySettings.boldText) {
          lightTheme = _applyBoldText(lightTheme);
          darkTheme = _applyBoldText(darkTheme);
        }

        return MaterialApp.router(
          routerConfig: _router,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _mapThemeMode(settings.themeMode),
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOutCubic,
          debugShowCheckedModeBanner: false,

          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            final style = isDark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                    statusBarBrightness: Brightness.dark,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                  );

            // ✅ font scale tüm uygulamada
            final mq = MediaQuery.of(context);
            final scaled = mq.copyWith(
              textScaler: TextScaler.linear(settings.fontScale),
            );

            // Get accessibility settings
            final accessibilitySettings = AccessibilitySettings.instance;

            // Build widget with accessibility wrapper
            Widget result = child ?? const SizedBox.shrink();
            
            // Ağ durumu banner'ı
            result = OfflineBanner(child: result);
            
            // Uygulama kilidi
            result = LockScreen(child: result);

            // Apply RTL if forced
            if (accessibilitySettings.forceRTL) {
              result = Directionality(
                textDirection: TextDirection.rtl,
                child: result,
              );
            }

            // Apply color blind filter if enabled
            if (accessibilitySettings.colorBlindMode > 0) {
              result = ColorFiltered(
                colorFilter: _getColorBlindFilter(accessibilitySettings.colorBlindMode),
                child: result,
              );
            }

            // Apply high contrast filter if enabled
            if (accessibilitySettings.highContrastMode) {
              result = ColorFiltered(
                colorFilter: _getHighContrastFilter(),
                child: result,
              );
            }

            // Apply bold text via MediaQuery if enabled
            if (accessibilitySettings.boldText) {
              result = MediaQuery(
                data: scaled.copyWith(boldText: true),
                child: result,
              );
            }

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: style,
              child: MediaQuery(
                data: scaled,
                child: result,
              ),
            );
          },
        );
      },
    );
  }

  // High contrast theme for light mode
  ThemeData _applyHighContrast(ThemeData theme) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: const Color(0xFF7B3FF2),
        surface: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.black26,
    );
  }

  // High contrast theme for dark mode
  ThemeData _applyHighContrastDark(ThemeData theme) {
    return theme.copyWith(
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: const Color(0xFFB794F6),
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: const Color(0xFF121212),
      dividerColor: Colors.white24,
    );
  }

  // Apply bold text throughout the app
  ThemeData _applyBoldText(ThemeData theme) {
    return theme.copyWith(
      textTheme: theme.textTheme.copyWith(
        bodyLarge: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        bodySmall: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        labelMedium: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        labelSmall: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  // Get high contrast filter - increases contrast and saturation
  ColorFilter _getHighContrastFilter() {
    // Increase contrast matrix
    const double contrast = 1.3; // 30% more contrast
    const double translate = (1 - contrast) / 2 * 255;
    
    return const ColorFilter.matrix(<double>[
      contrast, 0, 0, 0, translate,
      0, contrast, 0, 0, translate,
      0, 0, contrast, 0, translate,
      0, 0, 0, 1, 0,
    ]);
  }

  // Get color filter for color blind modes
  ColorFilter _getColorBlindFilter(int mode) {
    switch (mode) {
      case 1: // Protanopia (Red-Green)
        return const ColorFilter.matrix(<double>[
          0.567, 0.433, 0.0, 0.0, 0.0,
          0.558, 0.442, 0.0, 0.0, 0.0,
          0.0, 0.242, 0.758, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case 2: // Deuteranopia (Green-Red)
        return const ColorFilter.matrix(<double>[
          0.625, 0.375, 0.0, 0.0, 0.0,
          0.7, 0.3, 0.0, 0.0, 0.0,
          0.0, 0.3, 0.7, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case 3: // Tritanopia (Blue-Yellow)
        return const ColorFilter.matrix(<double>[
          0.95, 0.05, 0.0, 0.0, 0.0,
          0.0, 0.433, 0.567, 0.0, 0.0,
          0.0, 0.475, 0.525, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }
}

/// Helper extension for easy navigation
extension NearNavigation on BuildContext {
  /// Navigate to chat: context.goToChat('chat123', messageId: 'msg456')
  void goToChat(String chatId, {String? messageId}) {
    if (messageId != null) {
      GoRouter.of(this).go('/chat/$chatId?msg=$messageId');
    } else {
      GoRouter.of(this).go('/chat/$chatId');
    }
  }

  /// Navigate to story: context.goToStory('user123')
  void goToStory(String userId) {
    GoRouter.of(this).go('/story/$userId');
  }

  /// Navigate to call: context.goToCall('user123', video: true)
  void goToCall(String userId, {bool video = false}) {
    GoRouter.of(this).go('/call/$userId?video=$video');
  }

  /// Navigate to settings
  void goToSettings() {
    GoRouter.of(this).go('/settings');
  }
}
