import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Sfx { pop, tap, flip, correct, wrong, match, celebrate, unlock }

/// Short game sounds, each paired with a haptic, so every practice action
/// has a little physical "click". Sound follows the Profile toggle; haptics
/// always play.
class SoundFx {
  SoundFx._();
  static final instance = SoundFx._();

  /// Set in tests so nothing touches the platform channels.
  static bool disabled = false;

  bool enabled = true;
  final _players = <Sfx, AudioPlayer>{};

  static const _haptic = {
    Sfx.pop: HapticFeedback.lightImpact,
    Sfx.tap: HapticFeedback.selectionClick,
    Sfx.flip: HapticFeedback.selectionClick,
    Sfx.correct: HapticFeedback.lightImpact,
    Sfx.wrong: HapticFeedback.heavyImpact,
    Sfx.match: HapticFeedback.lightImpact,
    Sfx.celebrate: HapticFeedback.mediumImpact,
    Sfx.unlock: HapticFeedback.mediumImpact,
  };

  Future<void> play(Sfx s) async {
    if (disabled) return;
    _haptic[s]!();
    if (!enabled) return;
    try {
      final p = _players[s] ??= AudioPlayer()
        ..setPlayerMode(PlayerMode.lowLatency)
        ..setReleaseMode(ReleaseMode.stop)
        ..setAudioContext(AudioContext(
          android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none, usageType: AndroidUsageType.game, contentType: AndroidContentType.sonification),
        ));
      await p.stop();
      await p.play(AssetSource('sfx/${s.name}.ogg'), volume: .7);
    } catch (e) {
      debugPrint('Sound unavailable: $e');
    }
  }
}
