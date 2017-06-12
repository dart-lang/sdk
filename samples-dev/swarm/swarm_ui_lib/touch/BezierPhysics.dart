// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of touch;

/**
 * Functions to model constant acceleration as a cubic Bezier
 * curve (http://en.wikipedia.org/wiki/Bezier_curve). These functions are
 * intended to generate the transition timing function for CSS transitions.
 * Please see
 * [http://www.w3.org/TR/css3-transitions/#transition-timing-function_tag].
 *
 * The main operation of computing a cubic Bezier is split up into multiple
 * functions so that, should it be required, more operations and cases can be
 * supported in the future.
 */
class BezierPhysics {
  static const _ONE_THIRD = 1 / 3;
  static const _TWO_THIRDS = 2 / 3;

  /**
   * A list [:[x1, y1, x2, y2]:] of the intermediate control points of a cubic
   * bezier when the final velocity is zero. This is a special case for which
   * these control points are constants.
   */
  static const List<num> _FINAL_VELOCITY_ZERO_BEZIER = const [
    _ONE_THIRD,
    _TWO_THIRDS,
    _TWO_THIRDS,
    1
  ];

  /**
   * Given consistent kinematics parameters for constant acceleration, returns
   * the intermediate control points of the cubic Bezier curve that models the
   * motion. All input values must have correct signs.
   * Returns a list [:[x1, y1, x2, y2]:] representing the intermediate control
   *     points of the cubic Bezier.
   */
  static List<num> calculateCubicBezierFromKinematics(num initialVelocity,
      num finalVelocity, num totalTime, num totalDisplacement) {
    // Total time must be greater than 0.
    assert(!GoogleMath.nearlyEquals(totalTime, 0) && totalTime > 0);
    // Total displacement must not be 0.
    assert(!GoogleMath.nearlyEquals(totalDisplacement, 0));
    // Parameters must form a consistent constant acceleration model in
    // Newtonian kinematics.
    assert(GoogleMath.nearlyEquals(totalDisplacement,
        (initialVelocity + finalVelocity) * 0.5 * totalTime));

    if (GoogleMath.nearlyEquals(finalVelocity, 0)) {
      return _FINAL_VELOCITY_ZERO_BEZIER;
    }
    List<num> controlPoint = _tangentLinesToQuadraticBezier(
        initialVelocity, finalVelocity, totalTime, totalDisplacement);
    controlPoint = _normalizeQuadraticBezier(
        controlPoint[0], controlPoint[1], totalTime, totalDisplacement);
    return _quadraticToCubic(controlPoint[0], controlPoint[1]);
  }

  /**
   * Given a quadratic curve crossing points (0, 0) and (x2, y2), calculates the
   * intermediate control point (x1, y1) of the equivalent quadratic Bezier
   * curve with starting point (0, 0) and ending point (x2, y2).
   * [m0] The slope of the line tangent to the curve at (0, 0).
   * [m2] The slope of the line tangent to the curve at a different
   *     point (x2, y2).
   * [x2] The x-coordinate of the other point on the curve.
   * [y2] The y-coordinate of the other point on the curve.
   * Returns a list [:[x1, y1]:] representing the intermediate
   *     control point of the quadratic Bezier.
   */
  static List<num> _tangentLinesToQuadraticBezier(
      num m0, num m2, num x2, num y2) {
    if (GoogleMath.nearlyEquals(m0, m2)) {
      return [0, 0];
    }
    num x1 = (y2 - x2 * m2) / (m0 - m2);
    num y1 = x1 * m0;
    return [x1, y1];
  }

  /**
   * Normalizes a quadratic Bezier curve to have end point at (1, 1).
   * [x1] The x-coordinate of the intermediate control point.
   * [y1] The y-coordinate of the intermediate control point.
   * [x2] The x-coordinate of the end point.
   * [y2] The y-coordinate of the end point.
   * Returns a list [:[x1, y1]:] representing the intermediate control point.
   */
  static List<num> _normalizeQuadraticBezier(num x1, num y1, num x2, num y2) {
    // The end point must not lie on any axes.
    assert(!GoogleMath.nearlyEquals(x2, 0) && !GoogleMath.nearlyEquals(y2, 0));
    return [x1 / x2, y1 / y2];
  }

  /**
   * Converts a quadratic Bezier curve defined by the control points
   * (x0, y0) = (0, 0), (x1, y1) = (x, y), and (x2, y2) = (1, 1) into an
   * equivalent cubic Bezier curve with four control points. Note that the start
   * and end points will be unchanged.
   * [x] The x-coordinate of the intermediate control point.
   * [y] The y-coordinate of the intermediate control point.
   * Returns a list [:[x1, y1, x2, y2]:] containing the two
   *     intermediate points of the equivalent cubic Bezier curve.
   */
  static List<num> _quadraticToCubic(num x, num y) {
    // The intermediate control point must have coordinates within the
    // interval [0,1].
    assert(x >= 0 && x <= 1 && y >= 0 && y <= 1);
    num x1 = x * _TWO_THIRDS;
    num y1 = y * _TWO_THIRDS;
    num x2 = x1 + _ONE_THIRD;
    num y2 = y1 + _ONE_THIRD;
    return [x1, y1, x2, y2];
  }
}
