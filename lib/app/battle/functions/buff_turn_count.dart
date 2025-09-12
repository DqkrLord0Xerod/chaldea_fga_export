import 'dart:math';

import 'package:chaldea/models/models.dart';
import '../models/battle.dart';

// FuncType.shortenBuffturn:
// FuncType.extendBuffturn:
// FuncType.shortenBuffcount:
// FuncType.extendBuffcount:
class BuffTurnCount {
  const BuffTurnCount._();

  static void changeBuffValue(
    final BattleData battleData,
    final FuncType funcType,
    final DataVals dataVals,
    final List<BattleServantData> targets,
  ) {
    final functionRate = dataVals.Rate ?? 1000;
    if (functionRate < battleData.options.threshold) {
      return;
    }

    int value = dataVals.Value ?? 0;
    final bool isTurn = funcType == FuncType.shortenBuffturn || funcType == FuncType.extendBuffturn;
    final bool isShorten = funcType == FuncType.shortenBuffturn || funcType == FuncType.shortenBuffcount;
    if (isShorten) {
      value *= -1;
    }
    if (isTurn) {
      value *= 2;
    }
    for (final target in targets) {
      final success = _changeBuffValue(battleData, target, value, dataVals, isTurn);
      battleData.setFuncResult(target.uniqueId, success);
    }
  }

  static bool _changeBuffValue(
    final BattleData battleData,
    final BattleServantData svt,
    final int changeValue,
    final DataVals dataVals,
    final bool isTurn,
  ) {
    final List<int> targetIndiv = dataVals.TargetList ?? [];
    if (targetIndiv.isEmpty) return false;

    bool changed = false;

    final ignoreIndivUnreleaseable = dataVals.IgnoreIndivUnreleaseable == 1;
    final buffs = svt.getBuffsWithTraits(targetIndiv, ignoreIndivUnreleaseable: ignoreIndivUnreleaseable);
    for (final buff in buffs) {
      final minValue = dataVals.AllowRemoveBuff == 1 ? 0 : 1;
      if (isTurn && buff.logicTurn > 0) {
        buff.logicTurn = max(buff.logicTurn + changeValue, minValue);
        changed = true;
      } else if (!isTurn && buff.count > 0) {
        buff.count = max(buff.count + changeValue, minValue);
        changed = true;
      }
    }

    return changed;
  }
}
