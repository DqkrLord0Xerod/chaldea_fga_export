import 'package:chaldea/models/gamedata/common.dart';
import 'package:chaldea/models/userdata/battle.dart';
import 'package:chaldea/utils/fga_export.dart';
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
}
