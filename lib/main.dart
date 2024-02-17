import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image, Gradient;
import 'package:flutter/material.dart';
import 'package:rumble_game/buildings/tree.dart';
import 'package:rumble_game/game_core/enums.dart';

void main() {
  final myGame = MyGame();
  runApp(
    GameWidget(game: myGame, overlayBuilderMap: {
      'game_over': (_, MyGame game) => GameOver(game),
    }),
  );
}

class MyGame extends FlameGame with HasCollisionDetection {
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(Tree(priority: 0, team: Team.red));
    add(Tree(priority: 0, team: Team.red, suffix: TreeSuffix.midBoss1));
    add(Tree(priority: 0, team: Team.red, suffix: TreeSuffix.midBoss2));

    add(Tree(priority: 0, team: Team.cyan));
    add(Tree(priority: 0, team: Team.cyan, suffix: TreeSuffix.midBoss1));
    add(Tree(priority: 0, team: Team.cyan, suffix: TreeSuffix.midBoss2));
  }
}

class GameOver extends StatelessWidget {
  const GameOver(this.game, {super.key});

  final MyGame game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var humansTrees = game.children.query<Tree>().where((element) => element.team == Team.cyan).length;
    var orcsTrees = game.children.query<Tree>().where((element) => element.team == Team.red).length;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Wrap(
          children: [
            Column(
              children: [
                if (humansTrees > orcsTrees)
                  Text(
                    'Humans wins!',
                    style: textTheme.displayLarge,
                  ),
                if (orcsTrees > humansTrees)
                  Text(
                    'Orcs wins!',
                    style: textTheme.displayLarge,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
