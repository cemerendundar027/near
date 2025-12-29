// Shared Widgets Export
// This file exports all shared widgets for easy imports

export 'widgets/emoji_picker.dart';
export 'widgets/voice_recorder.dart' hide VoiceMessagePlayer;
export 'widgets/media_preview.dart' hide MediaType, MediaItem;
export 'widgets/message_reactions.dart';
export 'widgets/disappearing_messages.dart';
export 'widgets/wallpaper_picker.dart';
export 'widgets/qr_code.dart';
export 'widgets/typing_indicator.dart';
export 'widgets/message_input.dart';
export 'widgets/state_widgets.dart' hide ChatListShimmer;
export 'widgets/notification_badges.dart';

// New widgets
export 'widgets/formatted_text.dart';
export 'widgets/quick_replies.dart';
export 'widgets/swipe_actions.dart';
export 'widgets/chat_lock.dart';
export 'widgets/contact_card.dart';
export 'widgets/story_creator.dart';
export 'widgets/media_gallery.dart';
export 'widgets/link_preview.dart';
export 'widgets/chat_wallpaper.dart';
export 'widgets/voice_message.dart';
export 'widgets/near_branding.dart';

// Additional UI widgets
export 'widgets/gif_picker.dart';
export 'widgets/shimmer_loading.dart';
export 'widgets/network_status.dart';
export 'widgets/multi_select.dart';
