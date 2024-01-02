import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:rumble_game/game_core/enums.dart';
import 'package:rumble_game/main.dart';
import 'package:rumble_game/units/units_impl.dart';

class Tree extends SpriteComponent with HasGameReference<MyGame> {
  Tree({
    required this.team,
    this.suffix = TreeSuffix.boss,
    super.priority,
  }) : super(size: Vector2(12, 16), key: ComponentKey.named('Tree-${team.name}-${suffix.name}'));

  final Team team;
  final TreeSuffix suffix;

  late double hp = suffix == TreeSuffix.boss ? 10 : 3;

  double getAttacked(double dmg) {
    if (hp > 0) {
      hp -= dmg;
    }
    if (hp <= 0) {
      game.remove(this);
    }
    return hp;
  }

  @override
  Future<void> onLoad() async {
    add(
      RectangleHitbox(
        size: Vector2(size.x, size.y / 3),
        position: Vector2(0, size.y * .66),
        isSolid: true,
        collisionType: CollisionType.active,
      ),
    );

    scale = Vector2.all(5 * (suffix == TreeSuffix.boss ? 1.5 : 1));
    center = switch (suffix) {
      TreeSuffix.boss => switch (team) {
          Team.red => Vector2(game.size.x / 2, center.y + 50),
          Team.cyan => Vector2(game.size.x / 2, game.size.y - size.y * scale.x),
        },
      TreeSuffix.midBoss1 => switch (team) {
          Team.red => Vector2(game.size.x * .33, center.y + 150),
          Team.cyan => Vector2(game.size.x * .33, game.size.y - size.y * scale.x - 150),
        },
      TreeSuffix.midBoss2 => switch (team) {
          Team.red => Vector2(game.size.x * .66, center.y + 150),
          Team.cyan => Vector2(game.size.x * .66, game.size.y - size.y * scale.x - 150),
        },
    };
    sprite = await Sprite.load('tree.png');
    Future.delayed(const Duration(seconds: 5)).then((value) {
      _randomGenerateUnits();
    });
  }

  _randomGenerateUnits() async {
    while (!isRemoved) {
      if (game.children.query<OrcGrunt>().length <= 3) {
        var randomGenerated = Random().nextInt(150).abs();
        if (randomGenerated < 30) {
          switch (team) {
            case Team.red:
              var newOrc = OrcGrunt();
              newOrc.center = center;
              newOrc.targetStaticQueue.addAll([
                game.findByKeyName('Tree-${Team.cyan.name}-${TreeSuffix.boss.name}'),
                game.findByKeyName('Tree-${Team.cyan.name}-${suffix.name}')
              ]);
              game.add(newOrc);
              break;
            case Team.cyan:
              var newHuman = HumanSoldier();

              newHuman.center = center;
              newHuman.targetStaticQueue.addAll([
                game.findByKeyName('Tree-${Team.red.name}-${TreeSuffix.boss.name}'),
                game.findByKeyName('Tree-${Team.red.name}-${suffix.name}')
              ]);
              game.add(newHuman);
              break;
          }
        }
      }

      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
