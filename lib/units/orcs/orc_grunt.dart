import 'package:flame/components.dart';
import 'package:rumble_game/units/unit_base.dart';

class OrcGrunt extends UnitBase {
  OrcGrunt({super.key}) : super(spriteSheetPath: 'orc_soldier_red.png', unitTeam: UnitTeam.red);
}

class HumanSoldier extends UnitBase {
  HumanSoldier({super.key}) : super(spriteSheetPath: 'human_soldier_cyan.png', unitTeam: UnitTeam.cyan);

  @override
  Future<void> onLoad() async {
    position = Vector2(32, 180);
    await super.onLoad();
  }

  bool _shouldMarchRight = true;

  @override
  void update(double dt) {

    if (target == null) {
      if (position.x > game.size.x * .8) {
        _shouldMarchRight = false;
      } else if (position.x < game.size.x * .2) {
        _shouldMarchRight = true;
      }

      if (_shouldMarchRight) {
        current = UnitState.walkingRight;
      } else {
        current = UnitState.walkingLeft;
      }
    }

    super.update(dt);
  }
}
