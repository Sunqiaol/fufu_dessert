import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();
  
  bool _isInitialized = false;

  late AudioPlayer _musicPlayer;
  late AudioPlayer _sfxPlayer;
  
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 0.8;
  
  static const String _musicEnabledKey = 'music_enabled';
  static const String _sfxEnabledKey = 'sfx_enabled';
  static const String _musicVolumeKey = 'music_volume';
  static const String _sfxVolumeKey = 'sfx_volume';

  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _musicPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    
    await _loadSettings();
    
    // Set initial volumes
    await _musicPlayer.setVolume(_isMusicEnabled ? _musicVolume : 0.0);
    await _sfxPlayer.setVolume(_isSfxEnabled ? _sfxVolume : 0.0);
    
    _isInitialized = true;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _isSfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;
    _musicVolume = prefs.getDouble(_musicVolumeKey) ?? 0.6;
    _sfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 0.8;
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, _isMusicEnabled);
    await prefs.setBool(_sfxEnabledKey, _isSfxEnabled);
    await prefs.setDouble(_musicVolumeKey, _musicVolume);
    await prefs.setDouble(_sfxVolumeKey, _sfxVolume);
  }

  // Background Music
  Future<void> playBackgroundMusic() async {
    if (!_isMusicEnabled) return;
    
    // Use print feedback only for now
    _playProgrammaticBackground();
  }
  
  void _playProgrammaticBackground() {
    // Simple programmatic background music placeholder
    print('🎵 Background music would be playing now...');
  }

  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (_isMusicEnabled) {
      await _musicPlayer.resume();
    }
  }

  // Sound Effects
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (!_isSfxEnabled) return;
    
    // Use print feedback only for now
    _printSoundEffect(effect);
  }
  
  void _printSoundEffect(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.merge:
        print('🌟 *merge sound*');
        break;
      case SoundEffect.coin:
        print('💰 *cha-ching!*');
        break;
      case SoundEffect.serve:
        print('🍽️ *serve sound*');
        break;
      case SoundEffect.craft:
        print('👩‍🍳 *craft sound*');
        break;
      case SoundEffect.customerEnter:
        print('👋 *customer enters*');
        break;
      case SoundEffect.customerLeave:
        print('👋 *customer leaves*');
        break;
      case SoundEffect.buttonPress:
        print('🔘 *button press*');
        break;
      default:
        print('🔊 *${effect.name} sound*');
    }
  }
  
  String _getSoundEffectUrl(SoundEffect effect) {
    // Simple online sound effects - you can replace these with local files later
    switch (effect) {
      case SoundEffect.coin:
        return 'https://www.soundjay.com/misc/sounds/coin-drop-1.wav';
      case SoundEffect.buttonPress:
        return 'https://www.soundjay.com/misc/sounds/click1.wav';
      default:
        return ''; // Will use print fallback
    }
  }

  String _getSoundEffectFile(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.merge:
        return 'audio/merge.wav';
      case SoundEffect.sell:
        return 'audio/sell.wav';
      case SoundEffect.craft:
        return 'audio/craft.wav';
      case SoundEffect.serve:
        return 'audio/serve.wav';
      case SoundEffect.coin:
        return 'audio/coin.wav';
      case SoundEffect.levelUp:
        return 'audio/level_up.wav';
      case SoundEffect.customerEnter:
        return 'audio/customer_enter.wav';
      case SoundEffect.customerLeave:
        return 'audio/customer_leave.wav';
      case SoundEffect.buttonPress:
        return 'audio/button_press.wav';
    }
  }

  // Settings
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    if (enabled) {
      await _musicPlayer.setVolume(_musicVolume);
      await playBackgroundMusic();
    } else {
      await _musicPlayer.setVolume(0.0);
    }
    await _saveSettings();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    await _sfxPlayer.setVolume(enabled ? _sfxVolume : 0.0);
    await _saveSettings();
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (_isMusicEnabled) {
      await _musicPlayer.setVolume(_musicVolume);
    }
    await _saveSettings();
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    if (_isSfxEnabled) {
      await _sfxPlayer.setVolume(_sfxVolume);
    }
    await _saveSettings();
  }

  void dispose() {
    if (_isInitialized) {
      _musicPlayer.dispose();
      _sfxPlayer.dispose();
      _isInitialized = false;
      print('AudioService disposed');
    }
  }
}

enum SoundEffect {
  merge,
  sell,
  craft,
  serve,
  coin,
  levelUp,
  customerEnter,
  customerLeave,
  buttonPress,
}