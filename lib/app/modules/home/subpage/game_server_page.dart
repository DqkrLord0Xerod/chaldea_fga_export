import 'package:flutter/material.dart';

import 'package:chaldea/generated/l10n.dart';
import 'package:chaldea/models/models.dart';
import 'package:chaldea/widgets/tile_items.dart';

class GameServerPage extends StatefulWidget {
  GameServerPage({super.key});

  @override
  _GameServerPageState createState() => _GameServerPageState();
}

class _GameServerPageState extends State<GameServerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.game_server)),
      body: SingleChildScrollView(
        child: RadioGroup<Region>(
          groupValue: db.curUser.region,
          onChanged: (v) {
            setState(() {
              if (v != null) db.curUser.region = v;
            });
            db.notifyUserdata();
          },
          child: TileGroup(children: [for (var server in Region.values) radioOf(server)]),
        ),
      ),
    );
  }

  Widget radioOf(Region region) {
    return RadioListTile<Region>(
      value: region,
      title: Text(region.localName),
      subtitle: Text(region.language.name),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
