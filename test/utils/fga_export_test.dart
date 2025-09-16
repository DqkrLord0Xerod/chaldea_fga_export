import 'dart:convert';
import 'dart:io';

import 'package:chaldea/models/gamedata/common.dart';
import 'package:chaldea/models/userdata/battle.dart';
import 'package:chaldea/utils/fga_export.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

BattleShareData _shareDataWithAttacks(List<List<BattleAttackRecordData>> turns) {
  return BattleShareData(
    quest: null,
    formation: BattleTeamFormation(),
    actions: [
      for (final attacks in turns) BattleRecordData.attack(attacks: attacks),
    ],
  );
}

BattleAttackRecordData _normalCard({int svt = 0, CardType cardType = CardType.buster}) {
  return BattleAttackRecordData(
    svt: svt,
    isTD: false,
    cardType: cardType,
  );
}

BattleAttackRecordData _npCard(int svt) {
  return BattleAttackRecordData(
    svt: svt,
    isTD: true,
    cardType: CardType.arts,
  );
}

class _BattleConfigFixture {
  _BattleConfigFixture({
    required this.path,
    required this.name,
    required this.data,
    required this.expectedCommand,
    required this.expectedFields,
    required this.expectedNotesContains,
    this.expectedNotes,
  });

  factory _BattleConfigFixture.fromFile(File file) {
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final shareJson = Map<String, dynamic>.from(raw['share'] as Map);
    final expectedJson = Map<String, dynamic>.from(raw['expected'] as Map);
    final fields = <String, dynamic>{};
    final expectedFields = expectedJson['fields'];
    if (expectedFields is Map) {
      fields.addAll(Map<String, dynamic>.from(expectedFields));
    }
    final notesContains = expectedJson['notes_contains'];
    final expectedNotesContains = notesContains is List
        ? List<String>.from(notesContains)
        : const <String>[];
    final name = raw['name'] as String? ??
        raw['description'] as String? ??
        p.basenameWithoutExtension(file.path);

    return _BattleConfigFixture(
      path: file.path,
      name: name,
      data: BattleShareData.fromJson(shareJson),
      expectedCommand: expectedJson['autoskill_cmd'] as String,
      expectedFields: fields,
      expectedNotesContains: expectedNotesContains,
      expectedNotes: expectedJson['notes_equals'] as String?,
    );
  }

  final String path;
  final String name;
  final BattleShareData data;
  final String expectedCommand;
  final Map<String, dynamic> expectedFields;
  final List<String> expectedNotesContains;
  final String? expectedNotes;
}

List<_BattleConfigFixture> _loadBattleConfigFixtures() {
  final directory = Directory('test/data');
  if (!directory.existsSync()) {
    return const [];
  }

  final fixtures = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .map(_BattleConfigFixture.fromFile)
      .toList();
  fixtures.sort((a, b) => a.name.compareTo(b.name));
  return fixtures;
}

void main() {
  group('FGA attack translation', () {
    test('single NP in first slot', () {
      final data = _shareDataWithAttacks([
        [_npCard(0)],
      ]);
      final warnings = <String>[];

      final command = toFgaAutoSkillCommand(data, warnings: warnings);

      expect(command, '4');
      expect(warnings, isEmpty);
    });

    test('multiple NPs are exported as a sorted set', () {
      final data = _shareDataWithAttacks([
        [
          _normalCard(),
          _npCard(2),
          _npCard(0),
        ],
      ]);
      final warnings = <String>[];

      final command = toFgaAutoSkillCommand(data, warnings: warnings);

      expect(command, 'n146');
      expect(warnings, isEmpty);
    });

    test('no NP falls back to face cards', () {
      final data = _shareDataWithAttacks([
        [
          _normalCard(cardType: CardType.arts),
          _normalCard(cardType: CardType.quick),
          _normalCard(cardType: CardType.buster),
        ],
      ]);
      final warnings = <String>[];

      final command = toFgaAutoSkillCommand(data, warnings: warnings);

      expect(command, '0');
      expect(warnings, isEmpty);
    });

    test('NP after more than two cards emits a warning', () {
      final data = _shareDataWithAttacks([
        [
          _normalCard(),
          _normalCard(cardType: CardType.quick),
          _normalCard(cardType: CardType.arts),
          _npCard(1),
        ],
      ]);
      final warnings = <String>[];

      final command = toFgaAutoSkillCommand(data, warnings: warnings);

      expect(command, '0');
      expect(warnings, hasLength(1));
      expect(
        warnings.single,
        contains('at most two cards before an NP'),
      );
    });

    test('NP later in the turn after too many normals is rejected', () {
      final data = _shareDataWithAttacks([
        [
          _normalCard(),
          _npCard(0),
          _normalCard(cardType: CardType.quick),
          _normalCard(cardType: CardType.arts),
          _npCard(1),
        ],
      ]);
      final warnings = <String>[];

      final command = toFgaAutoSkillCommand(data, warnings: warnings);

      expect(command, '0');
      expect(warnings, hasLength(1));
      expect(
        warnings.single,
        contains('at most two cards before an NP'),
      );
    });
  });

  group('FGA order change detection', () {
    test('non-order-change mystic codes do not emit swap tokens', () {
      final data = BattleShareData(
        quest: null,
        formation: BattleTeamFormation(
          mysticCode: MysticCodeSaveData(mysticCodeId: 9700010, level: 10),
        ),
        delegate: BattleReplayDelegateData(
          replaceMemberIndexes: [
            [0, 1],
          ],
        ),
        actions: [
          BattleRecordData.skill(skill: 1),
        ],
      );

      final command = toFgaAutoSkillCommand(data);

      expect(command, 'k');
    });
  });

  group('FGA battle config fixtures', () {
    final fixtures = _loadBattleConfigFixtures();

    test('fixtures are available', () {
      expect(fixtures, isNotEmpty, reason: 'Battle config fixtures should exist.');
    });

    for (final fixture in fixtures) {
      test(fixture.name, () {
        final warnings = <String>[];
        final command = toFgaAutoSkillCommand(
          fixture.data,
          warnings: warnings,
        );

        expect(
          command,
          fixture.expectedCommand,
          reason: 'Fixture ${fixture.path} produced an unexpected AutoSkill command.',
        );

        final config = toFgaBattleConfig(fixture.data);

        expect(
          config['autoskill_cmd'],
          fixture.expectedCommand,
          reason: 'Fixture ${fixture.path} produced an unexpected AutoSkill command.',
        );

        fixture.expectedFields.forEach((key, value) {
          expect(
            config[key],
            value,
            reason: 'Fixture ${fixture.path} expected $key to equal $value.',
          );
        });

        final notes = config['autoskill_notes'];
        expect(notes, isA<String>(), reason: 'Fixture ${fixture.path} must set autoskill_notes.');
        final notesString = notes as String;

        if (warnings.isEmpty) {
          expect(
            notesString,
            isNot(contains('Warnings:')),
            reason: 'Fixture ${fixture.path} should not surface warnings.',
          );
        } else {
          expect(
            notesString,
            contains('Warnings:'),
            reason: 'Fixture ${fixture.path} did not record warnings in the notes.',
          );
          for (final warning in warnings) {
            expect(
              notesString,
              contains(warning),
              reason: 'Fixture ${fixture.path} notes should contain the warning "$warning".',
            );
          }
        }

        if (fixture.expectedNotes != null) {
          expect(
            notesString,
            fixture.expectedNotes,
            reason: 'Fixture ${fixture.path} produced unexpected notes.',
          );
        }

        for (final substring in fixture.expectedNotesContains) {
          expect(
            notesString,
            contains(substring),
            reason: 'Fixture ${fixture.path} notes should contain "$substring".',
          );
        }

        final jsonConfig = Map<String, dynamic>.from(
          jsonDecode(toFgaBattleConfigJson(fixture.data)) as Map,
        );
        expect(
          jsonConfig['autoskill_cmd'],
          fixture.expectedCommand,
          reason: 'JSON output for ${fixture.path} produced an unexpected AutoSkill command.',
        );
        expect(jsonConfig['autoskill_notes'], notesString);

        fixture.expectedFields.forEach((key, value) {
          expect(
            jsonConfig[key],
            value,
            reason: 'JSON output for ${fixture.path} expected $key to equal $value.',
          );
        });
      });
    }
  });
}
