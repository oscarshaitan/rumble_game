import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:rumble_game/main.dart';
import 'package:rumble_game/units/orcs/orc_grunt.dart';

class Tree extends SpriteComponent with HasGameReference<MyGame>, TapCallbacks, DoubleTapCallbacks {
  Tree({
    super.priority,
    super.key,
  }) : super(size: Vector2(12, 16), scale: Vector2.all(10), position: Vector2(0, 0));

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('tree2.png');
    position = Vector2(game.size.x / 2, game.size.y / 2);
  }

  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    var newOrc = OrcGrunt(key: ComponentKey.named('orc'));
    newOrc.center = Vector2(center.x, center.y - 96);
    game.add(newOrc);
  }
}
