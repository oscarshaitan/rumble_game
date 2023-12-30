import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:rumble_game/main.dart';
import 'package:rumble_game/units/units_impl.dart';

class Tree extends SpriteComponent with HasGameReference<MyGame>, TapCallbacks, DoubleTapCallbacks {
  Tree({
    super.priority,
    super.key,
  }) : super(size: Vector2(12, 16), scale: Vector2.all(10), position: Vector2(0, 0));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('tree2.png');
    position = Vector2(game.size.x / 2, game.size.y / 2);
    _randomGenerateUnits();
  }

  _randomGenerateUnits() async {
    while (true) {
      if (game.children.query<OrcGrunt>().length <= 3) {
        var randomGenerated = Random().nextInt(100).abs();
        if (randomGenerated < 30) {
          var newOrc = OrcGrunt();
          newOrc.center = Vector2(center.x, center.y - 96);
          game.add(newOrc);
        }
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }

  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    var newOrc = OrcGrunt();
    newOrc.center = Vector2(center.x, center.y - 96);
    game.add(newOrc);
  }
}
