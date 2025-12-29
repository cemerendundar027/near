import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Ses kayıt ve oynatma servisi (4.3)
class AudioService {
  AudioService._();
  static final instance = AudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  String? _currentRecordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentlyPlayingUrl;
  
  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  /// Kayıt izni kontrol
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Ses kaydını başlat
  Future<bool> startRecording() async {
    try {
      if (_isRecording) return false;
      
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        debugPrint('AudioService: Mikrofon izni yok');
        return false;
      }

      // Geçici dosya yolu oluştur
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_$timestamp.m4a';

      // Kayıt ayarları
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      debugPrint('AudioService: Kayıt başladı: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('AudioService: Kayıt başlatma hatası: $e');
      return false;
    }
  }

  /// Ses kaydını durdur ve dosyayı döndür
  Future<File?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          debugPrint('AudioService: Kayıt tamamlandı: $path (${await file.length()} bytes)');
          return file;
        }
      }
      
      debugPrint('AudioService: Kayıt dosyası oluşturulamadı');
      return null;
    } catch (e) {
      debugPrint('AudioService: Kayıt durdurma hatası: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Kaydı iptal et
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
        
        // Dosyayı sil
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      _currentRecordingPath = null;
      debugPrint('AudioService: Kayıt iptal edildi');
    } catch (e) {
      debugPrint('AudioService: Kayıt iptal hatası: $e');
    }
  }

  /// Ses dosyasını oynat
  Future<void> play(String url) async {
    try {
      // Başka bir ses çalıyorsa durdur
      if (_isPlaying) {
        await stop();
      }

      await _player.setUrl(url);
      _currentlyPlayingUrl = url;
      _isPlaying = true;
      
      // Oynatma bittiğinde state güncelle
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        }
      });

      await _player.play();
      debugPrint('AudioService: Oynatılıyor: $url');
    } catch (e) {
      debugPrint('AudioService: Oynatma hatası: $e');
      _isPlaying = false;
      _currentlyPlayingUrl = null;
    }
  }

  /// Oynatmayı duraklat
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  /// Oynatmayı durdur
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _currentlyPlayingUrl = null;
  }

  /// Belirli pozisyona git
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Oynatma pozisyonu stream'i
  Stream<Duration> get positionStream => _player.positionStream;

  /// Toplam süre
  Duration? get duration => _player.duration;

  /// Oynatma durumu stream'i
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Servisi temizle
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

