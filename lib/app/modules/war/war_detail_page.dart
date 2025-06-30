import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:auto_size_text/auto_size_text.dart';

import 'package:chaldea/app/api/atlas.dart';
import 'package:chaldea/app/app.dart';
import 'package:chaldea/app/modules/common/builders.dart';
import 'package:chaldea/app/modules/war/war/script_list.dart';
import 'package:chaldea/generated/l10n.dart';
import 'package:chaldea/models/models.dart';
import 'package:chaldea/utils/utils.dart';
import 'package:chaldea/widgets/carousel_util.dart';
import 'package:chaldea/widgets/region_based.dart';
import 'package:chaldea/widgets/widgets.dart';
import '../quest/quest_list.dart';
import 'war/asset_list.dart';
import 'war/chaldea_gate_quests.dart';
import 'war/free_overview.dart';
import 'war/map_list.dart';
import 'war/war_bgm_list.dart';
import 'war/war_map.dart';

class WarDetailPage extends StatefulWidget {
  final int? warId;
  final NiceWar? war;

  WarDetailPage({super.key, this.warId, this.war});

  @override
  _WarDetailPageState createState() => _WarDetailPageState();
}

class _WarDetailPageState extends State<WarDetailPage> with RegionBasedState<NiceWar, WarDetailPage> {
  int get warId => widget.war?.id ?? widget.warId ?? data?.id ?? 0;

  @override
  void initState() {
    super.initState();
    doFetchData();
  }

  @override
  Future<NiceWar?> fetchData(Region? r, {Duration? expireAfter}) async {
    NiceWar? _war;
    if (widget.war != null) return widget.war!;
    r ??= Region.jp;
    if (r == Region.jp && expireAfter == null) {
      _war ??= db.gameData.wars[widget.warId];
    }
    _war ??= await AtlasApi.war(warId, region: r, expireAfter: expireAfter);
    _war?.calcItems(db.gameData);
    return _war;
  }

  MainStoryPlan get plan => db.curUser.mainStoryOf(warId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(data?.lLongName.l.replaceAll('\n', ' ') ?? "War $warId", maxLines: 1),
        centerTitle: false,
        actions: [popupMenu],
      ),
      body: buildBody(context),
    );
  }

  @override
  Widget buildContent(BuildContext context, NiceWar war) {
    final banners = war.extra.allBanners;
    final warAdds = war.warAdds.toList()..sort2((e) => -e.startedAt);
    final eventAdds = war.event?.eventAdds ?? [];
    List<String> warBanners = {
      for (final warAdd in warAdds) warAdd.overwriteBanner,
      for (final eventAdd in eventAdds) eventAdd.overwriteBanner,
    }.whereType<String>().toList();
    warBanners = {
      war.shownBanner,
      if (war.parentWarId != ConstData.constants.grandBoardWarId) war.banner,
      ...warBanners.take(war.id == WarId.chaldeaGate ? 4 : 6).toList().reversed,
    }.whereType<String>().toList();

    List<Widget> children = [
      if (banners.isNotEmpty) CarouselUtil.limitHeightWidget(context: context, imageUrls: banners),
    ];

    List<String> shortNames = [war.lName.jp];
    List<String> longNames = [war.lLongName.jp];
    for (final warAdd in war.warAdds) {
      if (warAdd.type == WarOverwriteType.name && !shortNames.contains(warAdd.overwriteStr)) {
        shortNames.add(warAdd.overwriteStr);
      }
      if (warAdd.type == WarOverwriteType.longName && !longNames.contains(warAdd.overwriteStr)) {
        longNames.add(warAdd.overwriteStr);
      }
    }
    String lLongName = longNames.map((e) => Transl.warNames(e).l).join('\n');
    String longNameJp = longNames.join('\n');
    String lShortName = shortNames.map((e) => Transl.warNames(e).l).join('\n');
    String shortNameJp = shortNames.join('\n');

    children.add(
      CustomTable(
        selectable: true,
        children: [
          CustomTableRow(
            children: [
              TableCellData(
                text: lLongName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
                color: TableCellData.resolveHeaderColor(context),
              ),
            ],
          ),
          if (!Transl.isJP)
            CustomTableRow(
              children: [
                TableCellData(
                  text: longNameJp,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                  color: TableCellData.resolveHeaderColor(context).withAlpha(128),
                ),
              ],
            ),
          if (lShortName != lLongName) CustomTableRow.fromTexts(texts: [lShortName]),
          if (shortNameJp != longNameJp && !Transl.isJP) CustomTableRow.fromTexts(texts: [shortNameJp]),
          CustomTableRow(
            children: [
              TableCellData(text: S.current.war_age, isHeader: true),
              TableCellData(text: war.age, flex: 3),
            ],
          ),
          if (warBanners.isNotEmpty)
            CustomTableRow(
              children: [
                TableCellData(text: S.current.war_banner, isHeader: true),
                TableCellData(
                  flex: 3,
                  child: Wrap(
                    spacing: 4,
                    alignment: WrapAlignment.center,
                    children: warBanners
                        .map((e) => CachedImage(imageUrl: e, height: 48, showSaveOnLongPress: true))
                        .toList(),
                  ),
                ),
              ],
            ),
          if (war.eventId > 0)
            CustomTableRow(
              children: [
                TableCellData(isHeader: true, text: S.current.event),
                TableCellData(
                  flex: 3,
                  child: TextButton(
                    onPressed: () {
                      router.push(url: Routes.eventI(war.eventId), detail: true);
                    },
                    style: kTextButtonDenseStyle,
                    child: Text(
                      war.event?.lShortName.l ?? Transl.eventNames(war.eventName).l,
                      textAlign: TextAlign.center,
                      textScaler: const TextScaler.linear(0.9),
                    ),
                  ),
                ),
              ],
            ),
          if (kDebugMode && war.flags.isNotEmpty)
            CustomTableRow(
              children: [
                TableCellData(isHeader: true, text: 'flags'),
                TableCellData(
                  flex: 3,
                  child: Text(
                    war.flags.map((e) => e.name).join(' / '),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    if (war.spots.isNotEmpty || war.questSelections.isNotEmpty || war.id == WarId.grandBoardWar) {
      final grandBoardWarQuests = <Quest>[];
      String? header;
      if (war.id == WarId.grandBoardWar) {
        for (final _w in db.gameData.wars.values) {
          if (_w.parentWarId != WarId.grandBoardWar) continue;
          final candidateQuests = _w.quests.where((e) => e.isAnyFree).toList();
          candidateQuests.sortByList((e) => <Comparable>[e.recommendLevel, e.id]);
          if (candidateQuests.isNotEmpty) {
            grandBoardWarQuests.add(candidateQuests.last);
          }
        }
        header = '${S.current.quest} (Lv.100${kStarChar2 * 3})';
      }

      children.add(addQuestCategoryTile(context: context, war: war, extraQuests: grandBoardWarQuests, header: header));
    }

    final raidLink = war.event?.extra.script.raidLink;
    if (raidLink != null && raidLink.isNotEmpty) {
      children.add(buildRaidLinks(raidLink));
    }

    List<Widget> extraTiles = [];
    if (war.quests.any((q) => q.phaseScripts.isNotEmpty)) {
      extraTiles.add(
        ListTile(
          title: Text(S.current.script_story),
          onTap: () {
            router.pushPage(ScriptListPage(war: war));
          },
        ),
      );
      extraTiles.add(
        ListTile(
          title: Text(S.current.media_assets),
          enabled: !kIsWeb,
          onTap: () {
            router.pushPage(WarAssetListPage(war: war));
          },
        ),
      );
    }
    Set<int> bgms = {
      if (war.bgm != null) war.bgm!.id,
      ...war.warAdds.where((e) => e.type == WarOverwriteType.bgm).map((e) => e.overwriteId),
      ...war.maps.map((e) => e.bgm.id),
      ...eventAdds.where((e) => e.overwriteType == EventOverwriteType.bgm).map((e) => e.overwriteId),
    }.where((e) => e != 0).toSet();
    if (bgms.isNotEmpty) {
      if (bgms.length == 1) {
        final bgm = db.gameData.bgms[bgms.first];
        final name = bgm?.tooltip.setMaxLines(1);
        extraTiles.add(ListTile(title: Text(S.current.bgm), subtitle: name?.toText(), onTap: bgm?.routeTo));
      } else {
        extraTiles.add(
          ListTile(
            title: Text(S.current.bgm),
            onTap: () {
              router.pushPage(WarBgmListPage(bgmIds: bgms.toList()));
            },
          ),
        );
      }
    }
    final maps = war.maps.where((e) => e.mapImageW > 0 && e.mapImageH > 0).toList();
    if (maps.isNotEmpty) {
      if (maps.length == 1) {
        final map = maps.first;
        extraTiles.add(
          ListTile(
            title: Text('${S.current.war_map} ${map.id}'),
            onTap: () {
              router.push(
                child: WarMapPage(war: war, map: map),
              );
            },
          ),
        );
      } else {
        extraTiles.add(
          ListTile(
            title: Text(S.current.war_map),
            onTap: () {
              router.push(child: WarMapListPage(war: war));
            },
          ),
        );
      }
    }
    if (extraTiles.isNotEmpty) {
      children.add(TileGroup(children: extraTiles));
    }

    final subWars = db.gameData.wars.values.where((w) => w.parentWars.contains(war.id)).toList();
    if (war.flags.contains(WarFlag.areaBoardShortcut)) {
      final shortcutWar = db.gameData.wars[war.targetId];
      if (shortcutWar != null) subWars.add(shortcutWar);
    }
    if (subWars.isNotEmpty) {
      subWars.sort2((e) => -e.priority);
      List<Widget> warTiles = [];
      for (final _w in subWars) {
        warTiles.add(
          LayoutBuilder(
            builder: (context, constraints) {
              String title = _w.lLongName.l;
              return ListTile(
                leading: _w.shownBanner == null
                    ? null
                    : db.getIconImage(
                        _w.shownBanner,
                        height: min(constraints.maxWidth / 2, 164.0),
                        aspectRatio: 450 / 134,
                      ),
                horizontalTitleGap: 8,
                title: Text(
                  title.setMaxLines(1),
                  maxLines: 1,
                  textScaler: const TextScaler.linear(0.8),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  _w.routeTo();
                },
              );
            },
          ),
        );
      }
      children.add(TileGroup(header: 'Sub Wars', children: warTiles));
    }

    if (war.itemReward.isNotEmpty) {
      children.add(
        ListTile(
          title: Text(S.current.game_rewards),
          trailing: war.isMainStory
              ? db.onUserData(
                  (context, snapshot) => Switch.adaptive(
                    value: plan.questReward,
                    onChanged: (v) {
                      plan.questReward = v;
                      db.itemCenter.updateMainStory();
                    },
                  ),
                )
              : null,
          onTap: () {
            plan.questReward = !plan.questReward;
            db.itemCenter.updateMainStory();
          },
        ),
      );
      children.add(SharedBuilder.groupItems(context: context, items: war.itemReward, width: 48));
    }
    if (war.itemDrop.isNotEmpty) {
      children.add(
        ListTile(
          title: Text(S.current.quest_fixed_drop),
          trailing: war.isMainStory
              ? db.onUserData(
                  (context, snapshot) => Switch.adaptive(
                    value: plan.fixedDrop,
                    onChanged: (v) {
                      plan.fixedDrop = v;
                      db.itemCenter.updateMainStory();
                    },
                  ),
                )
              : null,
          onTap: () {
            plan.fixedDrop = !plan.fixedDrop;
            db.itemCenter.updateMainStory();
          },
        ),
      );
      children.add(SharedBuilder.groupItems(context: context, items: war.itemDrop, width: 48));
    }

    return ListView(children: children);
  }

  Widget get popupMenu {
    final war = data;
    return PopupMenuButton<dynamic>(
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          height: 32,
          child: Text('No.${widget.war?.id ?? widget.warId}', textScaler: const TextScaler.linear(0.9)),
        ),
        const PopupMenuDivider(),
        if (war != null)
          ...SharedBuilder.websitesPopupMenuItems(
            atlas: Atlas.dbWar(war.id),
            mooncell: war.extra.mcLink ?? war.event?.extra.mcLink,
            fandom: war.extra.fandomLink ?? war.event?.extra.fandomLink,
          ),
        if (war != null) ...SharedBuilder.noticeLinkPopupMenuItems(noticeLink: war.extra.noticeLink),
        if (warId > 0) ...[
          PopupMenuItem(
            child: Text(S.current.switch_region),
            onTap: () {
              _showSwitchRegion();
            },
          ),
          PopupMenuItem(
            child: Text(S.current.refresh),
            onTap: () {
              doFetchData(expireAfter: Duration.zero);
            },
          ),
        ],
      ],
    );
  }

  Widget? getCondWar() {
    NiceWar? condWar = data?.releaseCondWar;
    if (condWar == null) return null;
    return CustomTableRow(
      children: [
        TableCellData(isHeader: true, text: S.current.open_condition),
        TableCellData(
          flex: 3,
          child: TextButton(
            onPressed: () {
              condWar.routeTo();
            },
            style: kTextButtonDenseStyle,
            child: Text(condWar.lShortName, textAlign: TextAlign.center, textScaler: const TextScaler.linear(0.9)),
          ),
        ),
      ],
    );
  }

  Widget buildRaidLinks(Map<Region, String> raidLink) {
    return TileGroup(
      // header: S.current.event_raid,
      children: [
        for (final (region, url) in raidLink.items)
          ListTile(
            title: Text("[${region.localName}] ${S.current.event_raid} ${S.current.statistics_title}"),
            onTap: () {
              launch(url);
            },
          ),
      ],
    );
  }

  void _showSwitchRegion() {
    if (warId <= 0 || !mounted) return;
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => SimpleDialog(
        children: [
          ...Region.values.map((region) {
            final released = db.gameData.mappingData.warRelease.ofRegion(region);
            return ListTile(
              title: Text(region.localName),
              enabled: released == null || released.isEmpty || released.contains(warId),
              onTap: () async {
                Navigator.pop(context);
                this.region = region;
                doFetchData();
              },
            );
          }),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
    );
  }
}

Widget addQuestCategoryTile({
  required BuildContext context,
  NiceWar? war,
  Event? event,
  List<Quest> extraQuests = const [],
  String? header,
}) {
  final allQuests = [...extraQuests];
  if (war != null) {
    if (war.id == WarId.chaldeaGate) {
      final ignoreQuestIds = <int>{};
      for (final (eventId, ids) in db.gameData.others.eventQuestGroups.items) {
        final _event = db.gameData.events[eventId];
        if (_event == null) continue;
        if (const [80000, 80001, 80005, 80014].contains(eventId)) {
          ignoreQuestIds.addAll(ids);
          continue;
        }
        if (ids.length >= 15) ignoreQuestIds.addAll(ids);
      }
      allQuests.addAll(war.quests.where((q) => !ignoreQuestIds.contains(q.id)));
    } else {
      allQuests.addAll(war.quests);
    }
  }
  List<Quest> mainQuests = [],
      freeQuests = [],
      dailyEmber = [],
      dailyTraining = [],
      dailyQp = [],
      raidQuests = [],
      warBoardQuests = [],
      difficultQuests = [],
      oneOffQuests = [],
      interludeQuests = [],
      eventQuests = [],
      selectionQuests = [];
  for (final quest in allQuests) {
    if (quest.type == QuestType.main) {
      mainQuests.add(quest);
    } else if (quest.type == QuestType.friendship) {
      interludeQuests.add(quest);
    } else if (quest.type == QuestType.warBoard) {
      warBoardQuests.add(quest);
    } else if (quest.type == QuestType.free || (quest.type == QuestType.event && quest.afterClear.isRepeat)) {
      if (!quest.afterClear.isRepeat) {
        oneOffQuests.add(quest);
      } else if (quest.flags.contains(QuestFlag.raid)) {
        raidQuests.add(quest);
      } else if ([
        QuestFlag.notRetrievable,
        QuestFlag.dropFirstTimeOnly,
        QuestFlag.forceToNoDrop,
      ].any((flag) => quest.flags.contains(flag))) {
        difficultQuests.add(quest);
        // } else if (quest.flags.contains(QuestFlag.noBattle)) {
        //   eventQuests.add(quest);
      } else {
        if (quest.warId == WarId.daily) {
          if (quest.name.contains('種火集め')) {
            dailyEmber.add(quest);
          } else if (quest.name.contains('修練場')) {
            dailyTraining.add(quest);
          } else if (quest.name.contains('宝物庫の扉を開け')) {
            dailyQp.add(quest);
          } else {
            freeQuests.add(quest);
          }
        } else {
          freeQuests.add(quest);
        }
      }
    } else {
      eventQuests.add(quest);
    }
  }

  final selections = war?.questSelections.toList() ?? [];
  selections.sort2((e) => -e.priority);
  selectionQuests = selections.map((e) => e.quest).toList();

  List<Widget> children = [];

  void _addTile(String name, List<Quest> quests, {bool needSort = true}) {
    if (quests.isEmpty) return;
    children.add(
      ListTile(
        title: Text(name),
        trailing: Icon(DirectionalIcons.keyboard_arrow_forward(context)),
        onTap: () {
          router.push(
            child: QuestListPage(title: name, quests: quests, needSort: needSort, war: war),
          );
        },
      ),
    );
  }

  _addTile(S.current.main_quest, mainQuests);
  if (war?.id == 311) {
    freeQuests.sort((a, b) => Quest.compare(a, b, spotLayer: true));
    _addTile(S.current.free_quest, freeQuests, needSort: false);
  } else if (war?.id == WarId.ordealCall) {
    freeQuests.sort((a, b) => a.id - b.id);
    _addTile(S.current.free_quest, freeQuests, needSort: false);
  } else {
    _addTile(S.current.free_quest, freeQuests);
  }

  _addTile(S.current.daily_ember_quest, dailyEmber);
  _addTile(S.current.daily_training_quest, dailyTraining);
  _addTile(S.current.daily_qp_quest, dailyQp);
  _addTile(S.current.raid_quest, raidQuests);

  if (war?.id != WarId.daily && war?.id != WarId.chaldeaGate) {
    for (final (fqs, title) in [(freeQuests, S.current.free_quest), (raidQuests, S.current.raid_quest)]) {
      if (fqs.isEmpty) continue;
      children.add(
        ListTile(
          title: Text("${S.current.game_drop} ($title)"),
          trailing: Icon(DirectionalIcons.keyboard_arrow_forward(context)),
          onTap: () {
            router.pushPage(
              FreeQuestOverview(
                quests: fqs,
                isMainStory: war?.isMainStory ?? false,
                needSort: ![311, WarId.ordealCall].contains(war?.id),
              ),
            );
          },
        ),
      );
    }
  }
  _addTile(S.current.war_board, warBoardQuests);
  _addTile(S.current.event_quest, eventQuests);
  _addTile(S.current.one_off_quest, oneOffQuests);
  if (war?.id == WarId.advanced) {
    difficultQuests.sortByList((e) => <Comparable>[e.recommendLevel, -e.priority]);
    _addTile(S.current.high_difficulty_quest, difficultQuests, needSort: false);
  } else {
    _addTile(S.current.high_difficulty_quest, difficultQuests);
  }
  _addTile(S.current.interlude, interludeQuests);
  _addTile('Selections', selectionQuests, needSort: false);

  if (war?.id == WarId.chaldeaGate) {
    children.add(
      ListTile(
        title: Text("${S.current.sort_order}: ${S.current.time}"),
        trailing: Icon(DirectionalIcons.keyboard_arrow_forward(context)),
        onTap: () {
          router.push(child: const ChaldeaGateQuestListPage());
        },
      ),
    );
  }

  event ??= war?.eventReal;
  if (event != null && event.towers.isNotEmpty) {
    children.add(Divider(color: Theme.of(context).scaffoldBackgroundColor, thickness: 2, height: 2));
    for (final tower in event.towers) {
      final towerQuestIds =
          db.gameData.others.eventTowerQuestGroups[tower.towerId]?.toSet().intersection(
            allQuests.map((e) => e.id).toSet(),
          ) ??
          <int>{};
      if (towerQuestIds.isNotEmpty) {
        children.add(
          ListTile(
            dense: true,
            title: Text('${tower.lName}(${towerQuestIds.length})'),
            trailing: Icon(DirectionalIcons.keyboard_arrow_forward(context)),
            onTap: () {
              router.push(
                child: QuestListPage.ids(title: tower.lName, ids: towerQuestIds.toList()),
              );
            },
          ),
        );
      }
    }
  }

  return TileGroup(header: header ?? S.current.quest, children: children);
}
