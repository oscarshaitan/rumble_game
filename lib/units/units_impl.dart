import 'package:rumble_game/game_core/enums.dart';
import 'package:rumble_game/units/unit_base.dart';

class OrcGrunt extends UnitBase {
  OrcGrunt({super.key}) : super(spriteSheetPath: 'orc_soldier_red.png', team: Team.red, startingHP: 5);
}

class HumanSoldier extends UnitBase {
  HumanSoldier({super.key}) : super(spriteSheetPath: 'human_soldier_cyan.png', team: Team.cyan, startingHP: 5);
}
