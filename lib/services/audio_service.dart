import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();
  
  bool _isInitialized = false;

  late AudioPlayer _musicPlayer;
  
  // Track all active sound effect players
  final List<AudioPlayer> _activeSoundPlayers = [];
  
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;
  double _musicVolume = 0.6;
  double _sfxVolume = 0.8;
  
  // Track if audio should be playing
  bool _shouldBeActive = true;
  
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
    
    // Configure music player to keep audio focus for continuous playback
    await _musicPlayer.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.gain, // Keep audio focus for background music
      ),
    ));
    
    await _loadSettings();
    
    // Set initial volumes
    await _musicPlayer.setVolume(_isMusicEnabled ? _musicVolume : 0.0);
    
    // Set as active and start background music
    _shouldBeActive = true;
    
    // Start background music immediately
    await playBackgroundMusic();
    
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
    if (!_isMusicEnabled || !_shouldBeActive) {
      return;
    }
    
    try {
      // Play the Children's March Theme background music on loop
      await _musicPlayer.play(AssetSource('audio/Children\'s March Theme.mp3'));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop); // Loop the music
      await _musicPlayer.setVolume(_musicVolume);
    } catch (e) {
      debugPrint('Background music error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      await _musicPlayer.setVolume(0.0); // Force volume to 0
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled || !_shouldBeActive) {
      return;
    }
    
    try {
      final state = _musicPlayer.state;
      
      if (state == PlayerState.stopped) {
        // Music was stopped, restart it
        await playBackgroundMusic();
      } else {
        await _musicPlayer.resume();
        await _musicPlayer.setVolume(_musicVolume);
      }
    } catch (e) {
      debugPrint('Resume music error: $e');
      // If resume fails, try to restart completely
      await playBackgroundMusic();
    }
  }

  // Sound Effects
  Future<void> playSoundEffect(SoundEffect effect) async {
    if (!_isSfxEnabled || !_shouldBeActive) return;
    
    try {
      // Create a new AudioPlayer for each sound effect to avoid interfering with background music
      final soundPlayer = AudioPlayer();
      final soundFile = _getSoundEffectFile(effect);
      
      // Track this player so we can stop it if needed
      _activeSoundPlayers.add(soundPlayer);
      
      // Configure player to not take audio focus from background music
      await soundPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // Don't take audio focus!
        ),
      ));
      
      // Play the sound effect
      double effectiveVolume = _sfxVolume;
      // Make doorbell quieter (30% of normal SFX volume)
      if (effect == SoundEffect.doorbell) {
        effectiveVolume = _sfxVolume * 0.3;
      }
      await soundPlayer.setVolume(effectiveVolume);
      await soundPlayer.play(AssetSource(soundFile));
      
      // Dispose the player after the sound finishes and remove from tracking
      soundPlayer.onPlayerComplete.listen((_) {
        _activeSoundPlayers.remove(soundPlayer);
        soundPlayer.dispose();
      });
    } catch (e) {
      // Fallback to print feedback if audio file can't be loaded
      _printSoundEffect(effect);
    }
  }
  
  void _printSoundEffect(SoundEffect effect) {
    // Fallback for when audio files can't be loaded
    // In production, consider removing these completely
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
        return 'audio/level_up.mp3';
      case SoundEffect.customerEnter:
        return 'audio/customer_enter.wav';
      case SoundEffect.customerLeave:
        return 'audio/customer_leave.wav';
      case SoundEffect.buttonPress:
        return 'audio/button_press.wav';
      case SoundEffect.bubbleClick:
        return 'audio/bubble_click.ogg';
      case SoundEffect.moneyMerge:
        return 'audio/moeny_merge.mp3';
      case SoundEffect.doorbell:
        return 'audio/doorbell.mp3';
    }
  }

  // Settings
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    if (enabled) {
      await _musicPlayer.setVolume(_musicVolume);
      await playBackgroundMusic();
    } else {
      await stopBackgroundMusic();
    }
    await _saveSettings();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
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
    // SFX volume will be applied to individual sound players when created
    await _saveSettings();
  }

  // Stop all audio - background music and any playing sound effects
  Future<void> stopAllAudio() async {
    // Stop background music
    await stopBackgroundMusic();
    
    // Stop and dispose all active sound effect players
    for (final player in _activeSoundPlayers) {
      try {
        await player.stop();
        await player.setVolume(0.0); // Force volume to 0
        await player.dispose();
      } catch (e) {
        debugPrint('Error stopping sound player: $e');
      }
    }
    _activeSoundPlayers.clear();
  }

  // Deactivate audio system - stops all audio immediately
  void deactivateAudio() {
    _shouldBeActive = false;
    forceStopAllAudio();
  }
  
  // Reactivate audio system  
  void reactivateAudio() {
    _shouldBeActive = true;
    // Restart background music if it should be playing
    if (_isMusicEnabled) {
      playBackgroundMusic();
    }
  }
  
  // Force stop all audio immediately (nuclear option)
  void forceStopAllAudio() {
    try {
      // Stop background music aggressively
      _musicPlayer.stop();
      _musicPlayer.setVolume(0.0);
    } catch (e) {
      debugPrint('Error force stopping background music: $e');
    }
    
    // Stop all sound effects aggressively
    for (final player in _activeSoundPlayers.toList()) {
      try {
        player.stop();
        player.setVolume(0.0);
        player.dispose();
      } catch (e) {
        debugPrint('Error force stopping sound player: $e');
      }
    }
    _activeSoundPlayers.clear();
  }

  void dispose() {
    if (_isInitialized) {
      // Deactivate and stop all audio before disposing
      deactivateAudio();
      
      _musicPlayer.dispose();
      _isInitialized = false;
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
  bubbleClick,
  moneyMerge,
  doorbell,
}