import 'package:flame/components.dart';
import 'package:rumble_game/units/unit_base.dart';

class OrcGrunt extends UnitBase {
  OrcGrunt({ComponentKey? key}) : super('orc_grunt.png', key: key);

  @override
  bool get lockMove => false;

  @override
  UnitBase? get mainTarget => game.findByKeyName<UnitBase>('soldier')!;
}

class HumanSoldier extends UnitBase {
  HumanSoldier({ComponentKey? key}) : super('human_soldier_cyan.png', key: key);

  @override
  bool get lockMove => false;

  @override
  Future<void> onLoad() async {
    position = Vector2(32, 32);
    await super.onLoad();
  }

  bool _shouldMarchRight = true;

  @override
  void update(double dt) {
    mainTarget = game.findByKeyName<UnitBase>('orc');

    if (mainTarget == null) {
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
