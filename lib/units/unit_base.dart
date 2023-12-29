import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
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
}

enum UnitTeam {
  red,
  cyan;
}

class UnitBase extends SpriteAnimationGroupComponent<UnitState>
    with HasGameReference<MyGame>, TapCallbacks, DoubleTapCallbacks, CollisionCallbacks {
  UnitBase({
    required this.spriteSheetPath,
    required this.unitTeam,
    super.key,
  }) : super(size: Vector2.all(16), scale: Vector2.all(10), current: UnitState.idleTop);

  late SpriteSheet spriteSheet;

  final String spriteSheetPath;

  final UnitTeam unitTeam;
  bool lockMove = false;

  UnitBase? temporalTarget;
  UnitBase? mainTarget;

  UnitBase? get target => temporalTarget ?? mainTarget;

  double? get targetAngle => target == null ? null : _calculateAngle();

  @override
  Future<void> onLoad() async {
    debugMode = true;
    await _setUpAnimations();

    add(
      RectangleHitbox(
        size: Vector2.all(16),
        isSolid: true,
        collisionType: CollisionType.active,
      ),
    );

    add(
      RectangleHitbox(
        position: Vector2(-24, -24),
        size: Vector2.all(64),
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

    final walkingBottomAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 1, to: 5);
    final walkingBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 1, to: 5);
    final walkingRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 1, to: 5);
    final walkingTopRightAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 1, to: 5);
    final walkingTopAnimation = spriteSheet.createAnimation(row: 4, stepTime: 0.2, from: 1, to: 5);
    final walkingTopLeftAnimation = spriteSheet.createAnimation(row: 5, stepTime: 0.2, from: 1, to: 5);
    final walkingLeftAnimation = spriteSheet.createAnimation(row: 6, stepTime: 0.2, from: 1, to: 5);
    final walkingBottomLeftAnimation = spriteSheet.createAnimation(row: 7, stepTime: 0.2, from: 1, to: 5);

    final idleBottomAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 0, to: 1);
    final idleBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 0, to: 1);
    final idleRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 0, to: 1);
    final idleTopRightAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 0, to: 1);
    final idleTopAnimation = spriteSheet.createAnimation(row: 4, stepTime: 0.2, from: 0, to: 1);
    final idleTopLeftAnimation = spriteSheet.createAnimation(row: 5, stepTime: 0.2, from: 0, to: 1);
    final idleLeftAnimation = spriteSheet.createAnimation(row: 6, stepTime: 0.2, from: 0, to: 1);
    final idleBottomLeftAnimation = spriteSheet.createAnimation(row: 7, stepTime: 0.2, from: 0, to: 1);

    final attackBottomAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 5, to: 9);
    final attackBottomRightAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 5, to: 9);
    final attackRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 5, to: 9);
    final attackTopRightAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 5, to: 9);
    final attackTopAnimation = spriteSheet.createAnimation(row: 4, stepTime: 0.2, from: 5, to: 9);
    final attackTopLeftAnimation = spriteSheet.createAnimation(row: 5, stepTime: 0.2, from: 5, to: 9);
    final attackLeftAnimation = spriteSheet.createAnimation(row: 6, stepTime: 0.2, from: 5, to: 9);
    final attackBottomLeftAnimation = spriteSheet.createAnimation(row: 7, stepTime: 0.2, from: 5, to: 9);

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
    };
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    if (other is UnitBase) {
      if(other.unitTeam != unitTeam){
        temporalTarget = other;
      }
    }
    super.onCollision(intersectionPoints, other);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (lockMove) {
      current = UnitState.idleTop;
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
  }

  _attack() {
    var angle = targetAngle!;
    if (target != null) {
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
    const maxSpeed = 50;
    var maxSpeedNoAngle = sqrt(pow(maxSpeed, 2) / 2);
    //todo fix diagonals to use pitagoras
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
    var angle = _angleOfTarget(center, target!.center);

    return double.parse((angle).toStringAsFixed(2));
  }

  bool _isTargetOnAttackRange() {
    double distance = center.distanceTo(target!.center);

    return distance <= 70;
  }

  double _angleOfTarget(Vector2 unitPos, Vector2 targetPos) {
    Vector2 lineVector = unitPos - targetPos;
    double angleRadians = atan2(lineVector.y, lineVector.x);
    double angleDegrees = angleRadians * 180 / pi;
    return double.parse((angleDegrees).toStringAsFixed(2));
  }

  @override
  void onTapDown(event) {
    lockMove = !lockMove;
  }

  @override
  void onLongTapDown(event) {
    game.remove(this);
  }
}
