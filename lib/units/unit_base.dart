import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:rumble_game/buildings/tree.dart';
import 'package:rumble_game/game_core/enums.dart';
import 'package:rumble_game/main.dart';

enum UnitState {
  idleBottom,
  idleBottomRight,
  idleRight,
  idleTopRight,
  idleTop,
  idleTopLeft,
  idleLeft,
  idleBottomLeft,
  walkingBottom,
  walkingBottomRight,
  walkingRight,
  walkingTopRight,
  walkingTop,
  walkingTopLeft,
  walkingLeft,
  walkingBottomLeft,
  attackBottom,
  attackBottomRight,
  attackRight,
  attackTopRight,
  attackTop,
  attackTopLeft,
  attackLeft,
  attackBottomLeft,
  dieBottomRight,
}

class UnitBase extends SpriteAnimationGroupComponent<UnitState>
    with HasGameReference<MyGame>, TapCallbacks, DoubleTapCallbacks, CollisionCallbacks {
  UnitBase({
    required this.spriteSheetPath,
    required this.team,
    this.unitSize = 16,
    this.unitScale = 6,
    this.startingHP = 5,
    this.atk = 1,
    this.attackCooldown = 1.1,
    this.attackAnimationTime = 1,
    super.key,
  }) : super(
          size: Vector2.all(unitSize),
          scale: Vector2.all(unitScale),
          current: team == Team.red ? UnitState.walkingBottom : UnitState.walkingTop,
          removeOnFinish: {UnitState.dieBottomRight: true},
        ) {
    hp = startingHP;
  }

  late SpriteSheet spriteSheet;

  final String spriteSheetPath;
  final double unitSize;
  final double unitScale;
  final double startingHP;
  final double atk;
  final double attackCooldown;
  final double attackAnimationTime;
  late final Duration _attackAnimationTime =
      Duration(seconds: attackAnimationTime.floor(), milliseconds: ((attackAnimationTime % 1) * 100).toInt());
  late final Duration _attackCooldown =
      Duration(seconds: attackCooldown.floor(), milliseconds: ((attackCooldown % 1) * 100).toInt());

  final Team team;
  bool attackInCooldown = false;

  Set<Component?> targetStaticQueue = {};
  Set<Component> targetTemporalQueue = {};

  Component? get target {
    if (targetTemporalQueue.where((element) => !element.isRemoved).isNotEmpty) {
      return targetTemporalQueue.first;
    } else if (targetStaticQueue.where((element) => !(element?.isRemoved ?? true)).isNotEmpty) {
      return targetStaticQueue.last;
    } else {
      Future.delayed(Duration(seconds: 2)).then((value) {
        game.paused = true;
        game.overlays.add('game_over');
      });
      return null;
    }
  }

  double? get targetAngle => target == null ? null : _calculateAngle();

  @override
  Future<void> onLoad() async {
    await _setUpAnimations();

    _setUpHitboxes();
  }

  void _setUpHitboxes() {
    add(
      RectangleHitbox(
        size: Vector2(unitSize / 2, (unitSize / 2) * 1.3),
        position: Vector2(unitSize / 4, unitSize / 10),
        isSolid: true,
        collisionType: CollisionType.active,
      ),
    );

    add(
      RectangleHitbox(
        position: Vector2(-(unitSize * 1.5), -(unitSize * 1.5)),
        size: Vector2.all(unitSize * 4),
        isSolid: false,
        collisionType: CollisionType.passive,
      ),
    );
  }

  Future<void> _setUpAnimations() async {
    spriteSheet = SpriteSheet(
      image: await Flame.images.load(spriteSheetPath),
      srcSize: Vector2.all(32.0),
    );

    //<editor-fold desc="Walk animations">
    final walkingBottomAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 1, to: 5);
    final walkingBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 1, to: 5);
    final walkingRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 1, to: 5);
    final walkingTopRightAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 1, to: 5);
    final walkingTopAnimation = spriteSheet.createAnimation(row: 4, stepTime: 0.2, from: 1, to: 5);
    final walkingTopLeftAnimation = spriteSheet.createAnimation(row: 5, stepTime: 0.2, from: 1, to: 5);
    final walkingLeftAnimation = spriteSheet.createAnimation(row: 6, stepTime: 0.2, from: 1, to: 5);
    final walkingBottomLeftAnimation = spriteSheet.createAnimation(row: 7, stepTime: 0.2, from: 1, to: 5);
    //</editor-fold>

    //<editor-fold desc="Die animations">
    final dieBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.15, from: 20, to: 25, loop: false);
    //</editor-fold>

    //<editor-fold desc="Idle animations">
    final idleBottomAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 0, to: 1);
    final idleBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 0, to: 1);
    final idleRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 0, to: 1);
    final idleTopRightAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 0, to: 1);
    final idleTopAnimation = spriteSheet.createAnimation(row: 4, stepTime: 0.2, from: 0, to: 1);
    final idleTopLeftAnimation = spriteSheet.createAnimation(row: 5, stepTime: 0.2, from: 0, to: 1);
    final idleLeftAnimation = spriteSheet.createAnimation(row: 6, stepTime: 0.2, from: 0, to: 1);
    final idleBottomLeftAnimation = spriteSheet.createAnimation(row: 7, stepTime: 0.2, from: 0, to: 1);
    //</editor-fold>

    //<editor-fold desc="Attack Animations">

    int initialAttackFrame = 5;
    int finalAttackFrame = 9;
    final attackBottomAnimation = spriteSheet.createAnimation(
        row: 0,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackBottomRightAnimation = spriteSheet.createAnimation(
        row: 1,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackRightAnimation = spriteSheet.createAnimation(
        row: 2,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackTopRightAnimation = spriteSheet.createAnimation(
        row: 3,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackTopAnimation = spriteSheet.createAnimation(
        row: 4,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackTopLeftAnimation = spriteSheet.createAnimation(
        row: 5,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackLeftAnimation = spriteSheet.createAnimation(
        row: 6,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    final attackBottomLeftAnimation = spriteSheet.createAnimation(
        row: 7,
        stepTime: attackAnimationTime / (finalAttackFrame - initialAttackFrame),
        from: initialAttackFrame,
        to: finalAttackFrame);
    //</editor-fold>

    animations = {
      UnitState.idleBottom: idleBottomAnimation,
      UnitState.idleBottomRight: idleBottomRightAnimation,
      UnitState.idleRight: idleRightAnimation,
      UnitState.idleTopRight: idleTopRightAnimation,
      UnitState.idleTop: idleTopAnimation,
      UnitState.idleTopLeft: idleTopLeftAnimation,
      UnitState.idleLeft: idleLeftAnimation,
      UnitState.idleBottomLeft: idleBottomLeftAnimation,
      UnitState.walkingBottom: walkingBottomAnimation,
      UnitState.walkingBottomRight: walkingBottomRightAnimation,
      UnitState.walkingRight: walkingRightAnimation,
      UnitState.walkingTopRight: walkingTopRightAnimation,
      UnitState.walkingTop: walkingTopAnimation,
      UnitState.walkingTopLeft: walkingTopLeftAnimation,
      UnitState.walkingLeft: walkingLeftAnimation,
      UnitState.walkingBottomLeft: walkingBottomLeftAnimation,
      UnitState.attackBottom: attackBottomAnimation,
      UnitState.attackBottomRight: attackBottomRightAnimation,
      UnitState.attackRight: attackRightAnimation,
      UnitState.attackTopRight: attackTopRightAnimation,
      UnitState.attackTop: attackTopAnimation,
      UnitState.attackTopLeft: attackTopLeftAnimation,
      UnitState.attackLeft: attackLeftAnimation,
      UnitState.attackBottomLeft: attackBottomLeftAnimation,
      UnitState.dieBottomRight: dieBottomRightAnimation,
    };

    animationTickers?[UnitState.attackBottom]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackBottomRight]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackRight]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackTopRight]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackTop]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackTopLeft]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackLeft]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.attackBottomLeft]?.onComplete = _onAttackCompleted;
    animationTickers?[UnitState.dieBottomRight]?.onComplete = _onAttackCompleted;
  }

  _onAttackCompleted() {
    _attackOrRemove();
  }

  void _attackOrRemove() {
    if (target != null && !(target as Component).isRemoved && !isRemoved) {
      if (target is Tree) {
        if ((target as Tree).hp > 0) {
          var remainingHP = (target as Tree).getAttacked(atk);
          if (remainingHP <= 0) {
            targetStaticQueue.remove(target);
          }
        }
      }
      if (target is UnitBase) {
        if ((target as UnitBase).hp > 0) {
          var remainingHP = (target as UnitBase).getAttacked(atk);
          if (remainingHP <= 0) {
            targetTemporalQueue.remove(target);
          }
        }
      }
    } else {
      if (target is UnitBase) {
        targetTemporalQueue.remove(target);
      }
      if (target is Tree) {
        targetStaticQueue.remove(target);
      }
    }
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is UnitBase) {
      if (other.team != team) {
        targetTemporalQueue.add(other);
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void update(double dt) async {
    if (hp <= 0) {
      current = UnitState.dieBottomRight;
    } else {
      if (target != null) {
        if (_isTargetOnAttackRange()) {
          _attack();
        } else {
          _followTarget(dt);
        }
      } else {
        _walk(dt);
      }
    }

    super.update(dt);
  }

  _attack() async {
    if (target != null && !(target as Component).isRemoved) {
      if (!attackInCooldown) {
        attackInCooldown = true;
        var angle = targetAngle!;
        if (angle <= 22.5 && angle >= -22.5) {
          current = UnitState.attackLeft;
        } else if (angle > 22.5 && angle <= 67.5) {
          current = UnitState.attackTopLeft;
        } else if (angle > 67.5 && angle <= 112.5) {
          current = UnitState.attackTop;
        } else if (angle > 112.5 && angle <= 157.5) {
          current = UnitState.attackTopRight;
        } else if ((angle > 157.5 && angle > -157.5)) {
          current = UnitState.attackRight;
        } else if (angle < -112.5 && angle >= -157.5) {
          current = UnitState.attackBottomRight;
        } else if (angle < -67.5 && angle >= -112.5) {
          current = UnitState.attackBottom;
        } else if (angle < -22.5 && angle >= -67.5) {
          current = UnitState.attackBottomLeft;
        }

        await Future.delayed(_attackAnimationTime).then((_) {
          _attackOrRemove();
        });
        Future.delayed(_attackCooldown).then((_) {
          attackInCooldown = false;
        });
      }
    } else {
      if (target is UnitBase) {
        targetTemporalQueue.remove(target);
      } else {
        targetStaticQueue.remove(target);
      }
    }
  }

  _followTarget(double dt) {
    var angle = targetAngle!;
    if (angle <= 22.5 && angle >= -22.5) {
      current = UnitState.walkingLeft;
    } else if (angle > 22.5 && angle <= 67.5) {
      current = UnitState.walkingTopLeft;
    } else if (angle > 67.5 && angle <= 112.5) {
      current = UnitState.walkingTop;
    } else if (angle > 113.5 && angle <= 157.5) {
      current = UnitState.walkingTopRight;
    } else if ((angle > 157.5 && angle > -157.5)) {
      current = UnitState.walkingRight;
    } else if (angle < -113.5 && angle >= -157.5) {
      current = UnitState.walkingBottomRight;
    } else if (angle < -67.5 && angle >= -112.5) {
      current = UnitState.walkingBottom;
    } else if (angle < -22.5 && angle >= -67.5) {
      current = UnitState.walkingBottomLeft;
    }
    _walk(dt);
  }

  _walk(double dt) {
    const maxSpeed = 100;
    var maxSpeedNoAngle = sqrt(pow(maxSpeed, 2) / 2);
    var horizontalSpeed = targetAngle != null ? (maxSpeed * cos(targetAngle! * pi / 180)).abs() : maxSpeedNoAngle;
    var verticalSpeed = targetAngle != null ? (maxSpeed * sin(targetAngle! * pi / 180)).abs() : maxSpeedNoAngle;
    switch (current) {
      case UnitState.idleBottom:
      case UnitState.idleBottomRight:
      case UnitState.idleRight:
      case UnitState.idleTopRight:
      case UnitState.idleTop:
      case UnitState.idleTopLeft:
      case UnitState.idleLeft:
      case UnitState.idleBottomLeft:
        break;

      case UnitState.walkingBottom:
        position.y += dt * maxSpeed;
        break;
      case UnitState.walkingBottomRight:
        position.y += dt * verticalSpeed;
        position.x += dt * horizontalSpeed;
        break;
      case UnitState.walkingRight:
        position.x += dt * maxSpeed;
        break;
      case UnitState.walkingTopRight:
        position.y -= dt * verticalSpeed;
        position.x += dt * horizontalSpeed;
        break;
      case UnitState.walkingTop:
        position.y -= dt * maxSpeed;
        break;
      case UnitState.walkingTopLeft:
        position.y -= dt * verticalSpeed;
        position.x -= dt * horizontalSpeed;
        break;
      case UnitState.walkingLeft:
        position.x -= dt * maxSpeed;
        break;

      case UnitState.walkingBottomLeft:
        position.y += dt * verticalSpeed;
        position.x -= dt * horizontalSpeed;
        break;
      default:
        break;
    }

    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  double _calculateAngle() {
    var angle = _angleOfTarget(center, (target as PositionComponent).center);

    return double.parse((angle).toStringAsFixed(2));
  }

  bool _isTargetOnAttackRange() {
    double distance = center.distanceTo((target as PositionComponent).center);

    return distance <= unitSize * 2;
  }

  double _angleOfTarget(Vector2 unitPos, Vector2 targetPos) {
    Vector2 lineVector = unitPos - targetPos;
    double angleRadians = atan2(lineVector.y, lineVector.x);
    double angleDegrees = angleRadians * 180 / pi;
    return double.parse((angleDegrees).toStringAsFixed(2));
  }

  @override
  void onTapDown(event) {
    getAttacked(1);
  }

  late double hp;

  double getAttacked(double dmg) {
    if (hp > 0) {
      hp -= dmg;
    }
    return hp;
  }
}
