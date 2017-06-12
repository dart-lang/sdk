// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Implementations can be used to simulate the deceleration of an element within
 * a certain region. To use this behavior you need to provide an initial
 * velocity that is meant to represent the gesture that is initiating this
 * deceleration. You also provide the bounds of the region that the element
 * exists in, and the current offset of the element within that region. The
 * transitions will have the element decelerate to rest, or stretch past the
 * offset boundaries and then come to rest.
 *
 * This is primarily designed to solve the problem of slow scrolling in mobile
 * safari. You can use this along with the [Scroller] behavior to make a
 * scrollable area scroll the same way it would in a native application.
 *
 * Implementations of this interface do not maintain any references to HTML
 * elements, and therefore cannot do any redrawing of elements. They only
 * calculates where the element should be on an interval. It is the delegate's
 * responsibility to redraw the element when the onDecelerate callback is
 * invoked. It is recommended that you move the element with a hardware
 * accelerated method such as using 'translate3d' on the element's
 * -webkit-transform style property.
 */
abstract class Momentum {
  factory Momentum(MomentumDelegate delegate,
          [num defaultDecelerationFactor = 1]) =>
      new TimeoutMomentum(delegate, defaultDecelerationFactor);

  bool get decelerating;

  num get decelerationFactor;

  /**
  * Transition end handler. This function must be invoked after any transition
  * that occurred as a result of a call to the delegate's onDecelerate callback.
  */
  void onTransitionEnd();

  /**
   * Start decelerating.
   * The [velocity] passed should be in terms of number of pixels / millisecond.
   * [minCoord] and [maxCoord] specify the content's scrollable boundary.
   * The current offset of the element within its boundaries is specified by
   * [initialOffset].
   * Returns true if deceleration has been initiated.
   */
  bool start(Coordinate velocity, Coordinate minCoord, Coordinate maxCoord,
      Coordinate initialOffset,
      [num decelerationFactor]);

  /**
   * Calculate the velocity required to transition between coordinates [start]
   * and [target] optionally specifying a custom [decelerationFactor].
   */
  Coordinate calculateVelocity(Coordinate start, Coordinate target,
      [num decelerationFactor]);

  /** Stop decelerating and return the current velocity. */
  Coordinate stop();

  /** Aborts decelerating without dispatching any notification events. */
  void abort();

  /** null if no transition is in progress. */
  Coordinate get destination;
}

/**
 * Momentum Delegate interface.
 * You are required to implement this interface in order to use the
 * Momentum behavior.
 */
abstract class MomentumDelegate {
  /**
   * Callback for a deceleration step. The delegate is responsible for redrawing
   * the element in its new position specified in px.
   */
  void onDecelerate(num x, num y);

  /**
   * Callback for end of deceleration.
   */
  void onDecelerationEnd();
}

class BouncingState {
  static const NOT_BOUNCING = 0;
  static const BOUNCING_AWAY = 1;
  static const BOUNCING_BACK = 2;
}

class _Move {
  final num x;
  final num y;
  final num vx;
  final num vy;
  final num time;

  _Move(this.x, this.y, this.vx, this.vy, this.time);
}

/**
 * Secant method root solver helper class.
 * We use http://en.wikipedia.org/wiki/Secant_method
 * falling back to the http://en.wikipedia.org/wiki/Bisection_method
 * if it doesn't appear we are converging properlty.
 * TODO(jacobr): simplify the code so we don't have to use this solver
 * class at all.
 */
class Solver {
  static num solve(num fn(num), num targetY, num startX,
      [int maxIterations = 50]) {
    num lastX = 0;
    num lastY = fn(lastX);
    num deltaX;
    num deltaY;
    num minX = null;
    num maxX = null;
    num x = startX;
    num delta = startX;
    for (int i = 0; i < maxIterations; i++) {
      num y = fn(x);
      if (y.round() == targetY.round()) {
        return x;
      }
      if (y > targetY) {
        maxX = x;
      } else {
        minX = x;
      }

      num errorY = targetY - y;
      deltaX = x - lastX;
      deltaY = y - lastY;
      lastX = x;
      lastY = y;
      // Avoid divide by zero and as a hack just repeat the previous delta.
      // Obviously this is a little dangerous and we might not converge.
      if (deltaY != 0) {
        delta = errorY * deltaX / deltaY;
      }
      x += delta;
      if (minX != null && maxX != null && (x > minX || x < maxX)) {
        // Fall back to binary search.
        x = (minX + maxX) / 2;
      }
    }
    window.console.warn('''Could not find an exact solution. LastY=${lastY},
        targetY=${targetY} lastX=$lastX delta=$delta  deltaX=$deltaX
        deltaY=$deltaY''');
    return x;
  }
}

/**
 * Helper class modeling the physics of a throwable scrollable area along a
 * single dimension.
 */
class SingleDimensionPhysics {
  /** The number of frames per second the animation should run at. */
  static const _FRAMES_PER_SECOND = 60;

  /**
   * The spring coefficient for when the element has passed a boundary and is
   * decelerating to change direction and bounce back. Each frame, the velocity
   * will be changed by x times this coefficient, where x is the current stretch
   * value of the element from its boundary. This will end when velocity reaches
   * zero.
   */
  static const _PRE_BOUNCE_COEFFICIENT = 7.0 / _FRAMES_PER_SECOND;

  /**
   * The spring coefficient for when the element is bouncing back from a
   * stretched offset to a min or max position. Each frame, the velocity will
   * be changed to x times this coefficient, where x is the current stretch
   * value of the element from its boundary. This will end when the stretch
   * value reaches 0.
   */
  static const _POST_BOUNCE_COEFFICIENT = 7.0 / _FRAMES_PER_SECOND;

  /**
   * The number of milliseconds per animation frame.
   */
  static const _MS_PER_FRAME = 1000.0 / _FRAMES_PER_SECOND;

  /**
   * The constant factor applied to velocity at each frame to simulate
   * deceleration.
   */
  static const _DECELERATION_FACTOR = 0.97;

  static const _MAX_VELOCITY_STATIC_FRICTION = 0.08 * _MS_PER_FRAME;
  static const _DECELERATION_FACTOR_STATIC_FRICTION = 0.92;

  /**
   * Minimum velocity required to start or continue deceleration, in
   * pixels/frame. This is equivalent to 0.25 px/ms.
   */
  static const _MIN_VELOCITY = 0.25 * _MS_PER_FRAME;

  /**
   * Minimum velocity during a step, in pixels/frame. This is equivalent to 0.01
   * px/ms.
   */
  static const _MIN_STEP_VELOCITY = 0.01 * _MS_PER_FRAME;

  /**
   * Boost the initial velocity by a certain factor before applying momentum.
   * This just gives the momentum a better feel.
   */
  static const _INITIAL_VELOCITY_BOOST_FACTOR = 1.25;

  /**
   * Additional deceleration factor to apply for the current move only.  This
   * is helpful for cases such as scroll wheel scrolling where the default
   * amount of deceleration is inadequate.
   */
  num customDecelerationFactor = 1;
  num _minCoord;
  num _maxCoord;

  /** The bouncing state. */
  int _bouncingState;

  num velocity;
  num _currentOffset;

  /**
   * constant used when guessing at the velocity required to throw to a specific
   * location. Chosen arbitrarily. All that really matters is that the velocity
   * is large enough that a throw gesture will occur.
   */
  static const _VELOCITY_GUESS = 20;

  SingleDimensionPhysics() : _bouncingState = BouncingState.NOT_BOUNCING {}

  void configure(num minCoord, num maxCoord, num initialOffset,
      num customDecelerationFactor_, num velocity_) {
    _bouncingState = BouncingState.NOT_BOUNCING;
    _minCoord = minCoord;
    _maxCoord = maxCoord;
    _currentOffset = initialOffset;
    this.customDecelerationFactor = customDecelerationFactor_;
    _adjustInitialVelocityAndBouncingState(velocity_);
  }

  num solve(
      num initialOffset, num targetOffset, num customDecelerationFactor_) {
    initialOffset = initialOffset.round();
    targetOffset = targetOffset.round();
    if (initialOffset == targetOffset) {
      return 0;
    }
    return Solver.solve((num velocity_) {
      // Don't specify min and max coordinates as we don't need to bother
      // with the simulating bouncing off the edges.
      configure(null, null, initialOffset.round(), customDecelerationFactor_,
          velocity_);
      stepAll();
      return _currentOffset;
    }, targetOffset,
        targetOffset > initialOffset ? _VELOCITY_GUESS : -_VELOCITY_GUESS);
  }

  /**
   * Helper method to calculate initial velocity.
   * The [velocity] passed here should be in terms of number of
   * pixels / millisecond. Returns the adjusted x and y velocities.
   */
  void _adjustInitialVelocityAndBouncingState(num v) {
    velocity = v * _MS_PER_FRAME * _INITIAL_VELOCITY_BOOST_FACTOR;

    if (velocity.abs() < _MIN_VELOCITY) {
      if (_minCoord != null && _currentOffset < _minCoord) {
        velocity = (_minCoord - _currentOffset) * _POST_BOUNCE_COEFFICIENT;
        velocity = Math.max(velocity, _MIN_STEP_VELOCITY);
        _bouncingState = BouncingState.BOUNCING_BACK;
      } else if (_maxCoord != null && _currentOffset > _maxCoord) {
        velocity = (_currentOffset - _maxCoord) * _POST_BOUNCE_COEFFICIENT;
        velocity = -Math.max(velocity, _MIN_STEP_VELOCITY);
        _bouncingState = BouncingState.BOUNCING_BACK;
      }
    }
  }

  /**
   * Apply deceleration.
   */
  void _adjustVelocity() {
    num speed = velocity.abs();
    velocity *= _DECELERATION_FACTOR;
    if (customDecelerationFactor != null) {
      velocity *= customDecelerationFactor;
    }
    // This isn't really how static friction works but it is a plausible
    // approximation.
    if (speed < _MAX_VELOCITY_STATIC_FRICTION) {
      velocity *= _DECELERATION_FACTOR_STATIC_FRICTION;
    }

    num stretchDistance;
    if (_minCoord != null && _currentOffset < _minCoord) {
      stretchDistance = _minCoord - _currentOffset;
    } else {
      if (_maxCoord != null && _currentOffset > _maxCoord) {
        stretchDistance = _maxCoord - _currentOffset;
      }
    }
    if (stretchDistance != null) {
      if (stretchDistance * velocity < 0) {
        _bouncingState = _bouncingState == BouncingState.BOUNCING_BACK
            ? BouncingState.NOT_BOUNCING
            : BouncingState.BOUNCING_AWAY;
        velocity += stretchDistance * _PRE_BOUNCE_COEFFICIENT;
      } else {
        _bouncingState = BouncingState.BOUNCING_BACK;
        velocity = stretchDistance > 0
            ? Math.max(
                stretchDistance * _POST_BOUNCE_COEFFICIENT, _MIN_STEP_VELOCITY)
            : Math.min(stretchDistance * _POST_BOUNCE_COEFFICIENT,
                -_MIN_STEP_VELOCITY);
      }
    } else {
      _bouncingState = BouncingState.NOT_BOUNCING;
    }
  }

  void step() {
    // It is common for scrolling to be disabled so in these cases we want to
    // avoid needless calculations.
    if (velocity != null) {
      _currentOffset += velocity;
      _adjustVelocity();
    }
  }

  void stepAll() {
    while (!isDone()) {
      step();
    }
  }

  /**
   * Whether or not the current velocity is above the threshold required to
   * continue decelerating.
   */
  bool isVelocityAboveThreshold(num threshold) {
    return velocity.abs() >= threshold;
  }

  bool isDone() {
    return _bouncingState == BouncingState.NOT_BOUNCING &&
        !isVelocityAboveThreshold(_MIN_STEP_VELOCITY);
  }
}

/**
 * Implementation of a momentum strategy using webkit-transforms
 * and timeouts.
 */
class TimeoutMomentum implements Momentum {
  SingleDimensionPhysics physicsX;
  SingleDimensionPhysics physicsY;
  Coordinate _previousOffset;
  Queue<_Move> _moves;
  num _stepTimeout;
  bool _decelerating;
  MomentumDelegate _delegate;
  int _nextY;
  int _nextX;
  Coordinate _minCoord;
  Coordinate _maxCoord;
  num _customDecelerationFactor;
  num _defaultDecelerationFactor;

  TimeoutMomentum(this._delegate, [num defaultDecelerationFactor = 1])
      : _defaultDecelerationFactor = defaultDecelerationFactor,
        _decelerating = false,
        _moves = new Queue<_Move>(),
        physicsX = new SingleDimensionPhysics(),
        physicsY = new SingleDimensionPhysics();

  /**
   * Calculate and return the moves for the deceleration motion.
   */
  void _calculateMoves() {
    _moves.clear();
    num time = TimeUtil.now();
    while (!physicsX.isDone() || !physicsY.isDone()) {
      _stepWithoutAnimation();
      time += SingleDimensionPhysics._MS_PER_FRAME;
      if (_isStepNecessary()) {
        _moves.add(new _Move(
            _nextX, _nextY, physicsX.velocity, physicsY.velocity, time));
        _previousOffset.y = _nextY;
        _previousOffset.x = _nextX;
      }
    }
  }

  bool get decelerating => _decelerating;
  num get decelerationFactor => _customDecelerationFactor;

  /**
   * Checks whether or not an animation step is necessary or not. Animations
   * steps are not necessary when the velocity gets so low that in several
   * frames the offset is the same.
   * Returns true if there is movement to be done in the next frame.
   */
  bool _isStepNecessary() {
    return _nextY != _previousOffset.y || _nextX != _previousOffset.x;
  }

  /**
   * The [TouchHandler] requires this function but we don't need to do
   * anything here.
   */
  void onTransitionEnd() {}

  Coordinate calculateVelocity(Coordinate start_, Coordinate target,
      [num decelerationFactor = null]) {
    return new Coordinate(
        physicsX.solve(start_.x, target.x, decelerationFactor),
        physicsY.solve(start_.y, target.y, decelerationFactor));
  }

  bool start(Coordinate velocity, Coordinate minCoord, Coordinate maxCoord,
      Coordinate initialOffset,
      [num decelerationFactor = null]) {
    _customDecelerationFactor = _defaultDecelerationFactor;
    if (decelerationFactor != null) {
      _customDecelerationFactor = decelerationFactor;
    }

    if (_stepTimeout != null) {
      Env.cancelRequestAnimationFrame(_stepTimeout);
      _stepTimeout = null;
    }

    assert(_stepTimeout == null);
    assert(minCoord.x <= maxCoord.x);
    assert(minCoord.y <= maxCoord.y);
    _previousOffset = initialOffset.clone();
    physicsX.configure(minCoord.x, maxCoord.x, initialOffset.x,
        _customDecelerationFactor, velocity.x);
    physicsY.configure(minCoord.y, maxCoord.y, initialOffset.y,
        _customDecelerationFactor, velocity.y);
    if (!physicsX.isDone() || !physicsY.isDone()) {
      _calculateMoves();
      if (!_moves.isEmpty) {
        num firstTime = _moves.first.time;
        _stepTimeout = Env.requestAnimationFrame(_step, null, firstTime);
        _decelerating = true;
        return true;
      }
    }
    _decelerating = false;
    return false;
  }

  /**
   * Update the x, y values of the element offset without actually moving the
   * element. This is done because we store decimal values for x, y for
   * precision, but moving is only required when the offset is changed by at
   * least a whole integer.
   */
  void _stepWithoutAnimation() {
    physicsX.step();
    physicsY.step();
    _nextX = physicsX._currentOffset.round();
    _nextY = physicsY._currentOffset.round();
  }

  /**
   * Calculate the next offset of the element and animate it to that position.
   */
  void _step(num timestamp) {
    _stepTimeout = null;

    // Prune moves that are more than 1 frame behind when we have more
    // available moves.
    num lastEpoch = timestamp - SingleDimensionPhysics._MS_PER_FRAME;
    while (!_moves.isEmpty &&
        !identical(_moves.first, _moves.last) &&
        _moves.first.time < lastEpoch) {
      _moves.removeFirst();
    }

    if (!_moves.isEmpty) {
      final move = _moves.removeFirst();
      _delegate.onDecelerate(move.x, move.y);
      if (!_moves.isEmpty) {
        num nextTime = _moves.first.time;
        assert(_stepTimeout == null);
        _stepTimeout = Env.requestAnimationFrame(_step, null, nextTime);
      } else {
        stop();
      }
    }
  }

  void abort() {
    _decelerating = false;
    _moves.clear();
    if (_stepTimeout != null) {
      Env.cancelRequestAnimationFrame(_stepTimeout);
      _stepTimeout = null;
    }
  }

  Coordinate stop() {
    final wasDecelerating = _decelerating;
    _decelerating = false;
    Coordinate velocity;
    if (!_moves.isEmpty) {
      final move = _moves.first;
      // This is a workaround for the ugly hacks that get applied when a user
      // passed a velocity in to this Momentum implementation.
      num velocityScale = SingleDimensionPhysics._MS_PER_FRAME *
          SingleDimensionPhysics._INITIAL_VELOCITY_BOOST_FACTOR;
      velocity =
          new Coordinate(move.vx / velocityScale, move.vy / velocityScale);
    } else {
      velocity = new Coordinate(0, 0);
    }
    _moves.clear();
    if (_stepTimeout != null) {
      Env.cancelRequestAnimationFrame(_stepTimeout);
      _stepTimeout = null;
    }
    if (wasDecelerating) {
      _delegate.onDecelerationEnd();
    }
    return velocity;
  }

  Coordinate get destination {
    if (!_moves.isEmpty) {
      final lastMove = _moves.last;
      return new Coordinate(lastMove.x, lastMove.y);
    } else {
      return null;
    }
  }
}
