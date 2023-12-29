import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:rumble_game/buildings/sample.dart';
import 'package:rumble_game/units/orcs/orc_grunt.dart';

void main() {
  final myGame = MyGame();
  runApp(
    GameWidget(game: myGame),
  );
}

class MyGame extends FlameGame {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(Tree(priority: 1));
    add(HumanSoldier(key: ComponentKey.named('soldier')));
  }
}

class MyComponent extends SpriteComponent with HasGameReference<MyGame>, TapCallbacks, DoubleTapCallbacks {
  MyComponent()
      : super(
          size: Vector2.all(32),
          scale: Vector2.all(10),
        );

  @override
  void onDoubleTapUp(DoubleTapEvent event) {
    game.add(OrcGrunt(key: ComponentKey.named('orc')));
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('dirt.png');
  }
}