import 'package:chaldea/generated/l10n.dart';
import 'package:chaldea/widgets/widgets.dart';
import '../../../models/models.dart';
import '../common/filter_group.dart';
import '../common/filter_page_base.dart';

class EnemyFilterPage extends FilterPage<EnemyFilterData> {
  const EnemyFilterPage({super.key, required super.filterData, super.onChanged});

  @override
  _EnemyFilterPageState createState() => _EnemyFilterPageState();
}

class _EnemyFilterPageState extends FilterPageState<EnemyFilterData, EnemyFilterPage> {
  @override
  Widget build(BuildContext context) {
    return buildAdaptive(
      title: Text(S.current.filter, textScaler: const TextScaler.linear(0.8)),
      actions: getDefaultActions(
        onTapReset: () {
          filterData.reset();
          update();
        },
      ),
      content: getListViewBody(
        restorationId: 'enemy_list_filter',
        children: [
          getGroup(
            header: S.current.filter_sort,
            children: [
              FilterGroup.display(
                useGrid: filterData.useGrid,
                onChanged: (v) {
                  if (v != null) filterData.useGrid = v;
                  update();
                },
              ),
            ],
          ),
          getGroup(
            children: [
              for (int i = 0; i < filterData.sortKeys.length; i++)
                getSortButton<SvtCompare>(
                  prefix: '${i + 1}',
                  value: filterData.sortKeys[i],
                  items: {for (final e in EnemyFilterData.enemyCompares) e: e.showName},
                  onSortAttr: (key) {
                    filterData.sortKeys[i] = key ?? filterData.sortKeys[i];
                    update();
                  },
                  reversed: filterData.sortReversed[i],
                  onSortDirectional: (reversed) {
                    filterData.sortReversed[i] = reversed;
                    update();
                  },
                ),
            ],
          ),
          SwitchListTile.adaptive(
            value: filterData.onlyShowQuestEnemy,
            controlAffinity: ListTileControlAffinity.trailing,
            title: Text(S.current.only_show_main_story_enemy, textScaler: const TextScaler.linear(0.8)),
            onChanged: (v) {
              filterData.onlyShowQuestEnemy = v;
              update();
            },
          ),
          buildClassFilter(filterData.svtClass, showUnknown: true),
          FilterGroup<ServantSubAttribute>(
            title: Text(S.current.svt_sub_attribute, style: textStyle),
            options: ServantSubAttribute.validValues,
            values: filterData.attribute,
            optionBuilder: (v) => Text(Transl.svtSubAttribute(v).l),
            onFilterChanged: (value, _) {
              update();
            },
          ),
          FilterGroup<Region>(
            title: Text(S.current.game_server, style: textStyle),
            options: Region.values,
            values: filterData.region,
            optionBuilder: (v) => Text(v.localName),
            onFilterChanged: (v, _) {
              update();
            },
          ),
          FilterGroup<SvtType>(
            title: Text(S.current.general_type, style: textStyle),
            options: List.of(SvtType.values)
              ..removeWhere(
                (e) => [
                  SvtType.svtEquipMaterial,
                  // SvtType.enemyCollectionDetail,
                  SvtType.all,
                  SvtType.commandCode,
                ].contains(e),
              ),
            values: filterData.svtType,
            optionBuilder: (v) => Text(Transl.enums(v, (enums) => enums.svtType).l),
            onFilterChanged: (value, _) {
              update();
            },
          ),
          FilterGroup<int>(
            title: Text('${S.current.trait}*', style: textStyle),
            options: _traitsForFilter.map((e) => e.value).toList(),
            values: filterData.trait,
            optionBuilder: (v) => Text(Transl.traitName(v)),
            showMatchAll: true,
            showInvert: true,
            onFilterChanged: (value, _) {
              update();
            },
          ),
          SFooter(S.current.enemy_filter_trait_hint),
        ],
      ),
    );
  }
}

const _traitsForFilter = <Trait>[
  Trait.humanoid,
  Trait.human,
  Trait.genderFemale,
  Trait.genderMale,
  Trait.demonic,
  Trait.divine,
  Trait.dragon,
  Trait.demonBeast,
  Trait.wildbeast,
  Trait.demon,
  Trait.undead,
  Trait.oni,
  Trait.king,
  Trait.superGiant,
  Trait.giant,
  Trait.mechanical,
  Trait.greekMythologyMales,
  Trait.roman,
  Trait.fae,
  Trait.notBasedOnServant,
  Trait.servant,
];
