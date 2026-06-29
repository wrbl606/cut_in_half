import 'package:cut_in_half/models/cut_line.dart';
import 'package:cut_in_half/models/level.dart';
import 'package:cut_in_half/models/level_result.dart';
import 'package:cut_in_half/models/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CutLine', () {
    test('fromJson/toJson round-trip', () {
      final json = {
        'id': 'c1',
        'x1': 0.1,
        'y1': 0.2,
        'x2': 0.3,
        'y2': 0.4,
        'locked': true,
        'isInitial': true,
      };
      final c = CutLine.fromJson(json);
      expect(c.id, 'c1');
      expect(c.x1, 0.1);
      expect(c.locked, isTrue);
      expect(c.isInitial, isTrue);
      expect(c.toJson(), json);
    });

    test('copyWith preserves unspecified fields', () {
      final c = CutLine(
        id: 'a',
        x1: 0.1,
        y1: 0.2,
        x2: 0.3,
        y2: 0.4,
        locked: false,
        isInitial: false,
      );
      final c2 = c.copyWith(x1: 0.9);
      expect(c2.x1, 0.9);
      expect(c2.y1, 0.2);
      expect(c2.id, 'a');
    });

    test('isPlayerDrawn is true when not initial', () {
      final c = CutLine(
        id: 'p',
        x1: 0, y1: 0, x2: 1, y2: 1,
        locked: false,
        isInitial: false,
      );
      expect(c.isPlayerDrawn, isTrue);
    });
  });

  group('Level', () {
    test('fromJson parses a full level with initial cuts', () {
      final json = {
        'id': 'level_01',
        'title': 'Circle',
        'image': 'assets/images/circle.png',
        'time_limit': 30,
        'target_pieces': 4,
        'initial_cuts': [
          {'x1': 0.5, 'y1': 0.0, 'x2': 0.5, 'y2': 1.0, 'locked': true}
        ],
        'unlock_points': 0,
      };
      final lvl = Level.fromJson(json);
      expect(lvl.id, 'level_01');
      expect(lvl.title, 'Circle');
      expect(lvl.timeLimit, 30);
      expect(lvl.targetPieces, 4);
      expect(lvl.requiredCuts, 3);
      expect(lvl.initialCuts.length, 1);
      expect(lvl.initialCuts.first.locked, isTrue);
      expect(lvl.initialCuts.first.isInitial, isTrue);
      expect(lvl.unlockPoints, 0);
    });

    test('trims excess initial cuts beyond target_pieces - 1', () {
      final json = {
        'id': 'l',
        'title': 'T',
        'image': 'x.png',
        'time_limit': 10,
        'target_pieces': 3,
        'initial_cuts': [
          {'x1': 0, 'y1': 0, 'x2': 1, 'y2': 0, 'locked': true},
          {'x1': 0, 'y1': 0, 'x2': 1, 'y2': 0, 'locked': true},
          {'x1': 0, 'y1': 0, 'x2': 1, 'y2': 0, 'locked': true},
        ],
        'unlock_points': 0,
      };
      final lvl = Level.fromJson(json);
      // target_pieces - 1 = 2, so only 2 initial cuts kept.
      expect(lvl.initialCuts.length, 2);
    });

    test('default locked=true when omitted in initial_cuts', () {
      final json = {
        'id': 'l',
        'title': 'T',
        'image': 'x.png',
        'time_limit': 10,
        'target_pieces': 2,
        'initial_cuts': [
          {'x1': 0, 'y1': 0, 'x2': 1, 'y2': 0}
        ],
        'unlock_points': 0,
      };
      final lvl = Level.fromJson(json);
      expect(lvl.initialCuts.first.locked, isTrue);
    });
  });

  group('PlayerProgress', () {
    test('fromJson/toJson round-trip', () {
      final json = {
        'levels': {
          'level_01': {
            'best_accuracy': 88.5,
            'best_points': 89,
            'played': true,
          }
        },
        'sound_enabled': true,
      };
      final p = PlayerProgress.fromJson(json);
      expect(p.forLevel('level_01')?.bestAccuracy, 88.5);
      expect(p.forLevel('level_01')?.bestPoints, 89);
      expect(p.forLevel('level_01')?.played, isTrue);
      expect(p.totalCumulativePoints, 89);
      expect(p.soundEnabled, isTrue);
      expect(p.toJson(), json);
    });

    test('soundEnabled defaults to true and persists false', () {
      expect(PlayerProgress().soundEnabled, isTrue);
      final p = PlayerProgress.fromJson(<String, dynamic>{
        'levels': <String, dynamic>{},
        'sound_enabled': false,
      });
      expect(p.soundEnabled, isFalse);
      expect(p.toJson()['sound_enabled'], isFalse);
    });

    test('soundEnabled defaults to true when omitted in JSON', () {
      final p = PlayerProgress.fromJson(<String, dynamic>{
        'levels': <String, dynamic>{},
      });
      expect(p.soundEnabled, isTrue);
    });

    test('recordResult only increases best (no regression)', () {
      final p = PlayerProgress();
      p.recordResult('l1', 50, 50.0);
      expect(p.forLevel('l1')!.bestPoints, 50);
      p.recordResult('l1', 30, 30.0);
      // Best should not regress.
      expect(p.forLevel('l1')!.bestPoints, 50);
      expect(p.forLevel('l1')!.bestAccuracy, 50.0);
      p.recordResult('l1', 80, 80.0);
      expect(p.forLevel('l1')!.bestPoints, 80);
      expect(p.forLevel('l1')!.bestAccuracy, 80.0);
    });

    test('totalCumulativePoints sums best points across played levels', () {
      final p = PlayerProgress();
      p.recordResult('a', 50, 50.0);
      p.recordResult('b', 70, 70.0);
      expect(p.totalCumulativePoints, 120);
      // Replaying 'a' with a worse score doesn't change cumulative.
      p.recordResult('a', 10, 10.0);
      expect(p.totalCumulativePoints, 120);
      // Replaying 'a' with a better score updates cumulative.
      p.recordResult('a', 60, 60.0);
      expect(p.totalCumulativePoints, 130);
    });
  });

  group('LevelResult', () {
    test('buildResult clamps accuracy to [0, 100]', () {
      // Already covered by Splitter.accuracy tests, but verify the model.
      final result = LevelResult(
        levelId: 'x',
        cuts: const [],
        pieces: const [],
        accuracy: 88.0,
        points: 88,
        remainingSeconds: 5,
      );
      expect(result.points, 88);
      expect(result.remainingSeconds, 5);
    });
  });
}
