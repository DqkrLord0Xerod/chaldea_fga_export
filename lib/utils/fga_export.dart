import 'dart:collection';
import 'dart:convert';

import '../models/userdata/battle.dart';

const _kDefaultCardPriority = 'WB, WA, WQ, B, A, Q, RB, RA, RQ';
const _kDefaultServantPriority = '1,2,3,4,5,6';
// Known mystic code IDs whose kits provide Order Change.
const _kOrderChangeMysticCodeIds = <int>{20, 210};

Map<String, dynamic> toFgaBattleConfig(BattleShareData data) {
  final warnings = <String>[];
  final autoskillCommand = toFgaAutoSkillCommand(data, warnings: warnings);
  final quest = data.quest;
  final questNotes = <String>[];
  if (quest != null) {
    final region = quest.region?.name.toUpperCase();
    questNotes.add('Quest ${quest.id}/${quest.phase}${region == null ? '' : ' ($region)'}');
    if ((quest.enemyHash ?? '').isNotEmpty) {
      questNotes.add('Enemy hash ${quest.enemyHash}');
    }
  }

  final autoskillNotes = [
    'Imported from Chaldea',
    ...questNotes,
    if (warnings.isNotEmpty) ...[
      'Warnings:',
      for (final warning in warnings) '- $warning',
    ],
  ].join('\n');

  return {
    'autoskill_name': (data.formation.name ?? '').trim().isEmpty ? '--' : data.formation.name,
    'autoskill_cmd': autoskillCommand,
    'autoskill_notes': autoskillNotes,
    'card_priority': _kDefaultCardPriority,
    'auto_skill_rearrange_cards': '',
    'auto_skill_brave_chains': '',
    'shuffle_cards': 'None',
    'shuffle_cards_wave': 3,
    'use_servant_priority': false,
    'servant_priority': _kDefaultServantPriority,
    'spam_x': _defaultSpamConfigJson,
    'autoskill_party': -1,
    'battle_config_mat': <String>{},
    'battle_config_server': _serverFromRegion(quest?.region),
    'support_friend_names_list': <String>{},
    'support_pref_servant_list': <String>{},
    'support_pref_ce_mlb': false,
    'support_pref_ce_list': <String>{},
    'support_friends_only': false,
    'support_mode': 'Preferred',
    'support_fallback': 'Manual',
    'autoskill_support_class': 'None',
    'also_check_all': false,
    'support_max_ascended': false,
    'support_skill_max_1': false,
    'support_skill_max_2': false,
    'support_skill_max_3': false,
    'support_grand_servant': false,
    'support_bond_ce_effect': 'Ignore',
    'support_require_both_normal_and_reward_match': false,
    'auto_choose_target': false,
  };
}

String toFgaBattleConfigJson(BattleShareData data, {bool pretty = false}) {
  final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
  return encoder.convert(toFgaBattleConfig(data));
}

Uri toFgaBattleConfigDeepLink(BattleShareData data) {
  final json = toFgaBattleConfigJson(data);
  final encoded = base64Url.encode(utf8.encode(json));
  return Uri(scheme: 'fga', host: 'config', queryParameters: {'data': encoded});
}

String toFgaAutoSkillCommand(BattleShareData data, {List<String>? warnings}) {
  final waves = <List<String>>[];
  var currentWave = <String>[];
  var currentTurn = <String>[];
  int? currentEnemyTarget = 0;
  final orderChanges = ListQueue<List<int>>.from(data.delegate?.replaceMemberIndexes ?? const []);
  final mysticCodeId = data.formation.mysticCode.mysticCodeId;

  void finalizeTurn() {
    if (currentTurn.isEmpty) {
      return;
    }
    final turn = currentTurn.join();
    if (turn.isNotEmpty) {
      currentWave.add(turn);
    }
    currentTurn = <String>[];
  }

  void finalizeWave() {
    finalizeTurn();
    if (currentWave.isNotEmpty) {
      waves.add(currentWave);
      currentWave = <String>[];
    }
    currentEnemyTarget = 0;
  }

  for (final record in data.actions) {
    if (_isWaveProgress(record)) {
      finalizeWave();
      continue;
    }
    if (_isTurnProgress(record)) {
      finalizeTurn();
      continue;
    }

    final enemyTarget = _normalizeTarget(record.options.enemyTarget);
    if (enemyTarget != null) {
      if (currentEnemyTarget == null || enemyTarget != currentEnemyTarget) {
        final targetToken = _enemyTargetToken(enemyTarget);
        if (targetToken != null) {
          currentTurn.add(targetToken);
        }
      }
      currentEnemyTarget = enemyTarget;
    }

    switch (record.type) {
      case BattleRecordDataType.skill:
        final token = record.svt == null
            ? _masterSkillToken(record.skill)
            : _servantSkillToken(record.svt!, record.skill);
        if (token != null) {
          currentTurn.add(token);
        }
        if (record.svt == null && _looksLikeOrderChangeSkill(record, mysticCodeId) && orderChanges.isNotEmpty) {
          final change = orderChanges.removeFirst();
          final orderToken = _orderChangeToken(change);
          if (orderToken != null) {
            currentTurn.add(orderToken);
          }
        }
        break;
      case BattleRecordDataType.attack:
        final attackToken = _attackToken(record.attacks, warnings: warnings);
        if (attackToken != null && attackToken.isNotEmpty) {
          currentTurn.add(attackToken);
        }
        finalizeTurn();
        break;
      case BattleRecordDataType.base:
        break;
    }
  }

  finalizeWave();

  final waveStrings = waves.map((wave) => wave.join(',')).where((wave) => wave.isNotEmpty).toList();
  if (waveStrings.isEmpty) {
    return '';
  }
  return waveStrings.join(',#,');
}

bool _isWaveProgress(BattleRecordData record) {
  return record.type == BattleRecordDataType.base && record.skill == null;
}

bool _isTurnProgress(BattleRecordData record) {
  return record.type == BattleRecordDataType.base && record.skill != null;
}

int? _normalizeTarget(int? target) {
  if (target == null || target < 0 || target > 2) {
    return null;
  }
  return target;
}

String? _enemyTargetToken(int target) {
  if (target < 0 || target > 2) {
    return null;
  }
  return 't${target + 1}';
}

String? _servantSkillToken(int svtIndex, int? skillIndex) {
  if (skillIndex == null || svtIndex < 0 || svtIndex > 2 || skillIndex < 0 || skillIndex > 2) {
    return null;
  }
  final codeUnit = 'a'.codeUnitAt(0) + svtIndex * 3 + skillIndex;
  return String.fromCharCode(codeUnit);
}

String? _masterSkillToken(int? skillIndex) {
  if (skillIndex == null || skillIndex < 0 || skillIndex > 2) {
    return null;
  }
  return String.fromCharCode('j'.codeUnitAt(0) + skillIndex);
}

String? _orderChangeToken(List<int> pair) {
  if (pair.length < 2) {
    return null;
  }
  final starting = pair[0];
  final sub = pair[1];
  if (starting < 0 || starting > 2 || sub < 0 || sub > 2) {
    return null;
  }
  return 'x${starting + 1}${sub + 1}';
}

bool _looksLikeOrderChangeSkill(BattleRecordData record, int? mysticCodeId) {
  final skillIndex = record.skill;
  if (skillIndex == null || mysticCodeId == null) {
    return false;
  }
  if (!_isOrderChangeMysticCode(mysticCodeId)) {
    return false;
  }
  return skillIndex == 1;
}

bool _isOrderChangeMysticCode(int mysticCodeId) {
  final normalizedId = mysticCodeId.abs();
  if (_kOrderChangeMysticCodeIds.contains(normalizedId)) {
    return true;
  }
  final lastThreeDigits = normalizedId % 1000;
  return lastThreeDigits != normalizedId && _kOrderChangeMysticCodeIds.contains(lastThreeDigits);
}

/// Converts a recorded attack action into the compact representation expected by
/// FGA's AutoSkill format.
///
/// The exporter relies on a few assumptions about the recorded command cards:
///
/// * Every NP in the turn must appear within the first three cards. If an NP is
///   detected after more than two normal cards, the turn is exported as
///   face-card-only and a warning is recorded so the user can review the
///   mismatch.
/// * Multiple NPs in the same turn are treated as a set and ordered by the
///   servants' field slots (A → C) to match how FGA expects to receive them.
/// * Remaining face cards are ignored—FGA will automatically play whatever
///   normal cards are still available after the encoded NP sequence.
String? _attackToken(List<BattleAttackRecordData>? attacks, {List<String>? warnings}) {
  if (attacks == null || attacks.isEmpty) {
    return '0';
  }
  final nps = SplayTreeSet<_CommandCardNp>((a, b) => a.index.compareTo(b.index));
  var normalCardCount = 0;
  int? normalCardsBeforeFirstNp;

  for (final card in attacks) {
    if (card.isTD) {
      if (normalCardCount > 2) {
        warnings?.add(
          'Encountered an NP after $normalCardCount normal cards. FGA only supports at most two cards before an NP; the NP will be skipped.',
        );
        return '0';
      }

      normalCardsBeforeFirstNp ??= normalCardCount;

      final np = _CommandCardNp.fromSvtIndex(card.svt);
      if (np != null) {
        nps.add(np);
      }
    } else {
      normalCardCount += 1;
    }
  }

  if (nps.isEmpty) {
    return '0';
  }

  final buffer = StringBuffer();
  final leadingNormalCards = normalCardsBeforeFirstNp ?? 0;
  if (leadingNormalCards > 0) {
    buffer..write('n')..write(leadingNormalCards);
  }
  for (final np in nps) {
    buffer.write(np.code);
  }
  return buffer.toString();
}

String get _defaultSpamConfigJson {
  final defaultSkill = () => {
        'waves': [1, 2, 3],
        'spam': 'None',
        'target': 'None',
      };
  final defaultNp = () => {
        'waves': [1, 2, 3],
        'spam': 'None',
      };
  final config = List.generate(6, (_) => {
        'skills': List.generate(3, (_) => defaultSkill()),
        'np': defaultNp(),
      });
  return jsonEncode(config);
}

String _serverFromRegion(Region? region) {
  switch (region) {
    case Region.jp:
      return 'Jp';
    case Region.na:
      return 'En';
    case Region.cn:
      return 'Cn';
    case Region.tw:
      return 'Tw';
    case Region.kr:
      return 'Kr';
    case null:
      return '';
  }
}

enum _CommandCardNp {
  a('4'),
  b('5'),
  c('6');

  const _CommandCardNp(this.code);

  final String code;

  static _CommandCardNp? fromSvtIndex(int svtIndex) {
    switch (svtIndex) {
      case 0:
        return _CommandCardNp.a;
      case 1:
        return _CommandCardNp.b;
      case 2:
        return _CommandCardNp.c;
      default:
        return null;
    }
  }
}
