import 'package:tuple/tuple.dart';

import 'package:chaldea/packages/language.dart';
import 'package:chaldea/utils/utils.dart';
import '../models/models.dart';
import '../packages/platform/platform.dart';

class Atlas {
  Atlas._();

  static String get assetHost => HostsX.atlasAssetHost;
  static const String appHost = 'https://apps.atlasacademy.io/db/';
  static const String _dbAssetHost = 'https://cdn.jsdelivr.net/gh/atlasacademy/apps/packages/db/src/Assets/';

  static const _CommonAssets common = _CommonAssets();

  static bool isAtlasAsset(String url) {
    return url.startsWith(HostsX.atlasAsset.kGlobal) ||
        url.startsWith(HostsX.atlasAsset.kCN) ||
        url.startsWith(HostsX.atlasAsset.cn) ||
        url.startsWith(HostsX.atlasAsset.global);
  }

  /// db link
  static String dbUrl(String path, Object id, [Region region = Region.jp]) {
    String url = '$appHost${region.upper}/$path/$id';
    if (PlatformU.isIOS) {
      Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        String uiLang = "";
        String dataLang = "default";
        if (Language.isCHT) {
          uiLang = 'zh-TW';
        } else if (Language.isZH) {
          uiLang = 'zh-CN';
        } else if (Language.isEN) {
          dataLang = 'en';
        } else if (Language.isKO) {
          uiLang = 'ko-KR';
        }
        uri = uri.replace(
          queryParameters: {
            if (uiLang.isNotEmpty) 'lang': uiLang,
            if (dataLang.isNotEmpty) 'dataLang': dataLang,
            ...uri.queryParametersAll,
          },
        );
        url = uri.toString();
      }
    }
    return url;
  }

  static String dbServant(int id, [Region region = Region.jp]) {
    return dbUrl('servant', id, region);
  }

  static String dbCraftEssence(int id, [Region region = Region.jp]) {
    return dbUrl('craft-essence', id, region);
  }

  static String dbCommandCode(int id, [Region region = Region.jp]) {
    return dbUrl('command-code', id, region);
  }

  static String dbMasterMission(int id, [Region region = Region.jp]) {
    return dbUrl('master-mission', id, region);
  }

  static String dbEvent(int id, [Region region = Region.jp]) {
    return dbUrl('event', id, region);
  }

  static String dbWar(int id, [Region region = Region.jp]) {
    return dbUrl('war', id, region);
  }

  static String dbSkill(int id, [Region region = Region.jp]) {
    return dbUrl('skill', id, region);
  }

  static String dbTd(int id, [Region region = Region.jp]) {
    return dbUrl('noble-phantasm', id, region);
  }

  static String dbFunc(int id, [Region region = Region.jp]) {
    return dbUrl('func', id, region);
  }

  static String dbBuff(int id, [Region region = Region.jp]) {
    return dbUrl('buff', id, region);
  }

  static String dbQuest(int id, [int? phase, Region region = Region.jp]) {
    String idAndPhase = '$id';
    if (phase != null) idAndPhase += '/$phase';
    String url = dbUrl('quest', idAndPhase, region);
    return url;
  }

  static String ai(
    int id,
    bool isSvt, {
    Region region = Region.jp,
    int skillId1 = 0,
    int skillId2 = 0,
    int skillId3 = 0,
  }) {
    String url = dbUrl(isSvt ? 'ai/svt' : 'ai/field', id, region);
    Map<String, String> query = {
      if (skillId1 != 0) 'skillId1': skillId1.toString(),
      if (skillId2 != 0) 'skillId2': skillId2.toString(),
      if (skillId3 != 0) 'skillId3': skillId3.toString(),
    };
    if (query.isEmpty) return url;
    return Uri.parse(url).replace(queryParameters: query).toString();
  }

  static String asset(String path, [Region region = Region.jp]) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$assetHost/${region.upper}/$path';
  }

  static String classColor(int svtRarity) {
    return const {0: 'n', 1: 'b', 2: 'b', 3: 's', 4: 'g', 5: 'g'}[svtRarity] ?? 'g';
  }

  static String classCard(int svtRarity, int imageId) {
    int subId = 1;
    if (imageId == 10010) {
      // Grand Extra II
      imageId -= 1;
    } else if (imageId.isEven) {
      imageId -= 1;
      subId += 1;
    }
    return Atlas.asset('ClassCard/class_${classColor(svtRarity)}_$imageId@$subId.png');
  }

  static String classIcon(int svtRarity, int iconId) {
    int rarity = const {0: 0, 1: 1, 2: 1, 3: 2, 4: 3, 5: 3}[svtRarity] ?? 3;
    return Atlas.asset('ClassIcons/class${rarity}_$iconId.png');
  }

  static String assetItem(int id, [Region region = Region.jp]) {
    return '$assetHost/${region.upper}/Items/$id.png';
  }

  static String dbAsset(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$_dbAssetHost$path';
  }

  static Tuple2<Region, int?> resolveRegionInt(String path) {
    final match = RegExp(r'(\d+)').firstMatch(path);
    if (match == null) {
      return const Tuple2(Region.jp, null);
    }
    final id = int.tryParse(match.group(1)!);
    final regionText = RegExp(r'(JP|NA|CN|TW|KR)/').firstMatch(path)?.group(1);
    Region region = const RegionConverter().fromJson(regionText ?? "");
    return Tuple2(region, id);
  }
}

class AssetURL {
  static const baseUrl = 'https://static.atlasacademy.io';
  static final AssetURL i = AssetURL();

  final Region region;
  AssetURL([this.region = Region.jp]);
  AssetURL.parseRegion(String url) : region = Region.values.firstWhereOrNull((r) => url.contains('/$r/')) ?? Region.jp;

  late final String publicDir = '$baseUrl/$region';
  late final String extractDir = 'https://static.atlasacademy.io/file/aa-fgo-extract-${region.name.toLowerCase()}';

  String pad(int id, [int width = 5]) => id.toString().padLeft(width, '0');
  String extract(String path) => '$extractDir/$path';
  //
  String back(dynamic bgId, bool fullscreen) => "$publicDir/Back/back$bgId${fullscreen ? "_1344_626" : ""}.png";
  String charaGraph(int ascension, int itemId) =>
      {
        1: "$publicDir/CharaGraph/$itemId/${itemId}a@1.png",
        2: "$publicDir/CharaGraph/$itemId/${itemId}a@2.png",
        3: "$publicDir/CharaGraph/$itemId/${itemId}b@1.png",
        4: "$publicDir/CharaGraph/$itemId/${itemId}b@2.png",
      }[ascension] ??
      "";
  String charaGraphChange(int ascension, int itemId, String suffix) =>
      {
        0: "$publicDir/CharaGraph/$itemId/$itemId$suffix@1.png",
        1: "$publicDir/CharaGraph/$itemId/$itemId$suffix@2.png",
        3: "$publicDir/CharaGraph/$itemId/$itemId$suffix@1.png",
        4: "$publicDir/CharaGraph/$itemId/$itemId$suffix@2.png",
      }[ascension] ??
      "";
  String charaGraphEx(int ascension, int itemId) =>
      {
        1: "$publicDir/CharaGraph/CharaGraphEx/$itemId/${itemId}a@1.png",
        2: "$publicDir/CharaGraph/CharaGraphEx/$itemId/${itemId}a@2.png",
        3: "$publicDir/CharaGraph/CharaGraphEx/$itemId/${itemId}b@1.png",
        4: "$publicDir/CharaGraph/CharaGraphEx/$itemId/${itemId}b@2.png",
      }[ascension] ??
      '';
  String charaGraphExCostume(int itemId) => ("$publicDir/CharaGraph/CharaGraphEx/$itemId/${itemId}a.png");
  String commands(int itemId, int i) => "$publicDir/Servants/Commands/$itemId/card_servant_$i.png";
  String commandFile(int itemId, String fileName) => "$publicDir/Servants/Commands/$itemId/$fileName.png";
  String status(int itemId, int i) => "$publicDir/Servants/Status/$itemId/status_servant_$i.png";
  String charaGraphDefault(dynamic itemId) => "$publicDir/CharaGraph/$itemId/${itemId}a.png";
  String charaGraphName(int itemId, int i) => "$publicDir/CharaGraph/$itemId/${itemId}name@$i.png";
  String charaFigure(int itemId, int i) => "$publicDir/CharaFigure/$itemId$i/$itemId${i}_merged.png";
  int? getCharaFigureId(String url) {
    final charaId = RegExp(r'/CharaFigure/(\d+)/').firstMatch(url)?.group(1);
    return charaId == null ? null : int.tryParse(charaId);
  }

  String charaFigureId(dynamic figureId) => ("$publicDir/CharaFigure/$figureId/${figureId}_merged.png");
  String charaFigureForm(int formId, int svtScriptId) =>
      "$publicDir/CharaFigure/Form/$formId/$svtScriptId/${svtScriptId}_merged.png";
  String narrowFigure(int ascension, int itemId) =>
      {
        1: "$publicDir/NarrowFigure/$itemId/$itemId@0.png",
        2: "$publicDir/NarrowFigure/$itemId/$itemId@1.png",
        3: "$publicDir/NarrowFigure/$itemId/$itemId@2.png",
        4: "$publicDir/NarrowFigure/$itemId/${itemId}_2@0.png",
      }[ascension] ??
      "";
  String narrowFigureChange(int ascension, int itemId, String suffix) =>
      {
        0: "$publicDir/NarrowFigure/$itemId/$itemId$suffix@0.png",
        1: "$publicDir/NarrowFigure/$itemId/$itemId$suffix@1.png",
        3: "$publicDir/NarrowFigure/$itemId/$itemId$suffix@2.png",
        4: "$publicDir/NarrowFigure/$itemId/${itemId}_2$suffix@0.png",
      }[ascension] ??
      "";
  String image(String image) => "$publicDir/Image/$image/$image.png";
  String narrowFigureDefault(int itemId) => "$publicDir/NarrowFigure/$itemId/$itemId@0.png";
  String skillIcon(int itemId) => "$publicDir/SkillIcons/skill_${pad(itemId)}.png";
  String buffIcon(int itemId) => "$publicDir/BuffIcons/bufficon_$itemId.png";
  String items(int itemId) => "$publicDir/Items/$itemId.png";
  String coins(int itemId) => "$publicDir/Coins/$itemId.png";
  String face(int itemId, int i) => "$publicDir/Faces/f_$itemId$i.png";
  String faceId(int iconId) => "$publicDir/Faces/f_$iconId.png";
  String faceChange(int itemId, int i, String suffix) => "$publicDir/Faces/f_$itemId$i$suffix.png";
  String equipFace(int itemId, int i) => "$publicDir/EquipFaces/f_$itemId$i.png";
  String enemy(int itemId, int i) => "$publicDir/Enemys/$itemId$i.png";
  String enemyId(int itemId) => "$publicDir/Enemys/$itemId.png";
  String mcitem(int itemId) => "$publicDir/Items/masterequip${pad(itemId)}.png";
  String masterFace(int itemId) => "$publicDir/MasterFace/equip${pad(itemId)}.png";
  String masterFaceImage(int itemId) => "$publicDir/MasterFace/image${pad(itemId)}.png";
  String masterFigure(int itemId) => "$publicDir/MasterFigure/equip${pad(itemId)}.png";
  String enemyMasterFace(int itemId) => "$publicDir/EnemyMasterFace/enemyMasterFace$itemId.png";
  String enemyMasterFigure(int itemId) => "$publicDir/EnemyMasterFigure/figure$itemId.png";
  String commandSpell(int itemId) => "$publicDir/CommandSpell/cs_${pad(itemId, 4)}.png";
  String commandCode(int itemId) => "$publicDir/CommandCodes/c_$itemId.png";
  String commandGraph(int itemId) => "$publicDir/CommandGraph/${itemId}a.png";
  String audio(String folder, String id) => "$publicDir/Audio/$folder/$id.mp3";
  String banner(String banner) => "$publicDir/Banner/$banner.png";
  String eventUi(String event) => "$publicDir/EventUI/$event.png";
  String eventReward(String fname) => "$publicDir/EventReward/$fname.png";
  String mapImg(int mapId) =>
      "$publicDir/Terminal/MapImgs/img_questmap_${pad(mapId, 6)}/img_questmap_${pad(mapId, 6)}.png";
  String mapGimmickImg(int warAssetId, int gimmickId) =>
      "$publicDir/Terminal/QuestMap/Capter${pad(warAssetId, 6)}/QMap_Cap${pad(warAssetId, 6)}_Atlas/gimmick_${pad(gimmickId, 6)}.png";
  String spotImg(int warAssetId, int spotId) =>
      "$publicDir/Terminal/QuestMap/Capter${pad(warAssetId, 6)}/QMap_Cap${pad(warAssetId, 6)}_Atlas/spot_${pad(spotId, 6)}.png";
  String spotRoadImg(int warAssetId, int spotId) =>
      "$publicDir/Terminal/QuestMap/Capter${pad(warAssetId, 6)}/QMap_Cap${pad(warAssetId, 6)}_Atlas/img_road${pad(warAssetId, 6)}_00.png";
  String script(String scriptPath) => "$publicDir/Script/$scriptPath.txt";
  String bgmLogo(int logoId) => "$publicDir/MyRoomSound/soundlogo_${pad(logoId, 3)}.png";
  String servantModel(int itemId) => "$publicDir/Servants/$itemId/manifest.json";
  String movie(String itemId) => "$publicDir/Movie/$itemId.mp4";
  String marks(String itemId) => "$publicDir/Marks/$itemId.png";
  String svtTexture(dynamic battleCharaId) => "$publicDir/Servants/$battleCharaId/textures/$battleCharaId.png";
  String summonBanner(int imageId) => "$publicDir/SummonBanners/img_summon_$imageId.png";

  String commandAtlas(String name) => '$extractDir/Battle/Common/CommandAtlas/$name.png';
}

const _assetHost = Hosts0.kAtlasAssetHostGlobal;

class _CommonAssets {
  final emptyCeIcon =
      "$_assetHost/file/aa-fgo-extract-jp/Battle/BattleResult/PartyOrganizationAtlas/formation_blank_02.png";
  final emptySvtIcon = "$_assetHost/JP/Faces/f_1000000.png";
  final unknownEnemyIcon = "$_assetHost/JP/Faces/f_1000011.png";
  final emptySkillIcon = '$_assetHost/JP/SkillIcons/skill_999999.png';
  final unknownSkillIcon = '$_assetHost/JP/SkillIcons/skill_00001.png';

  const _CommonAssets();
}
