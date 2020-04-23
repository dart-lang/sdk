// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';

/// A border of a box, comprised of four sides: top, right, bottom, left.
///
/// The sides are represented by [BorderSide] objects.
///
/// {@tool sample}
///
/// All four borders the same, two-pixel wide solid white:
///
/// ```dart
/// Border.all(width: 2.0, color: const Color(0xFFFFFFFF))
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// The border for a material design divider:
///
/// ```dart
/// Border(bottom: BorderSide(color: Theme.of(context).dividerColor))
/// ```
/// {@end-tool}
/// {@tool sample}
///
/// A 1990s-era "OK" button:
///
/// ```dart
/// Container(
///   decoration: const BoxDecoration(
///     border: Border(
///       top: BorderSide(width: 1.0, color: Color(0xFFFFFFFFFF)),
///       left: BorderSide(width: 1.0, color: Color(0xFFFFFFFFFF)),
///       right: BorderSide(width: 1.0, color: Color(0xFFFF000000)),
///       bottom: BorderSide(width: 1.0, color: Color(0xFFFF000000)),
///     ),
///   ),
///   child: Container(
///     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
///     decoration: const BoxDecoration(
///       border: Border(
///         top: BorderSide(width: 1.0, color: Color(0xFFFFDFDFDF)),
///         left: BorderSide(width: 1.0, color: Color(0xFFFFDFDFDF)),
///         right: BorderSide(width: 1.0, color: Color(0xFFFF7F7F7F)),
///         bottom: BorderSide(width: 1.0, color: Color(0xFFFF7F7F7F)),
///       ),
///       color: Color(0xFFBFBFBF),
///     ),
///     child: const Text(
///       'OK',
///       textAlign: TextAlign.center,
///       style: TextStyle(color: Color(0xFF000000))
///     ),
///   ),
/// )
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [BoxDecoration], which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a material app, as shown in the "divider" sample above.
class Border extends BoxBorder {
  @override
  final BorderSide top;

  /// The right side of this border.
  final BorderSide right;

  @override
  final BorderSide bottom;

  /// The left side of this border.
  final BorderSide left;

  /// Creates a border.
  ///
  /// All the sides of the border default to [BorderSide.none].
  ///
  /// The arguments must not be null.
  const Border({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  })  : assert(top != null),
        assert(right != null),
        assert(bottom != null),
        assert(left != null);

  /// A uniform border with all sides the same color and width.
  ///
  /// The sides default to black solid borders, one logical pixel wide.
  factory Border.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) {
    final BorderSide side =
        BorderSide(color: color, width: width, style: style);
    return Border.fromBorderSide(side);
  }

  /// Creates a border whose sides are all the same.
  ///
  /// The `side` argument must not be null.
  const Border.fromBorderSide(BorderSide side)
      : assert(side != null),
        top = side,
        right = side,
        bottom = side,
        left = side;
}

/// A border of a box, comprised of four sides, the lateral sides of which
/// flip over based on the reading direction.
///
/// The lateral sides are called [start] and [end]. When painted in
/// left-to-right environments, the [start] side will be painted on the left and
/// the [end] side on the right; in right-to-left environments, it is the
/// reverse. The other two sides are [top] and [bottom].
///
/// The sides are represented by [BorderSide] objects.
///
/// If the [start] and [end] sides are the same, then it is slightly more
/// efficient to use a [Border] object rather than a [BorderDirectional] object.
///
/// See also:
///
///  * [BoxDecoration], which uses this class to describe its edge decoration.
///  * [BorderSide], which is used to describe each side of the box.
///  * [Theme], from the material layer, which can be queried to obtain appropriate colors
///    to use for borders in a material app, as shown in the "divider" sample above.
class BorderDirectional extends BoxBorder {
  @override
  final BorderSide top;

  /// The start side of this border.
  ///
  /// This is the side on the left in left-to-right text and on the right in
  /// right-to-left text.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which is used to describe the reading direction.
  final BorderSide start;

  /// The end side of this border.
  ///
  /// This is the side on the right in left-to-right text and on the left in
  /// right-to-left text.
  ///
  /// See also:
  ///
  ///  * [TextDirection], which is used to describe the reading direction.
  final BorderSide end;

  @override
  final BorderSide bottom;

  /// Creates a border.
  ///
  /// The [start] and [end] sides represent the horizontal sides; the start side
  /// is on the leading edge given the reading direction, and the end side is on
  /// the trailing edge. They are resolved during [paint].
  ///
  /// All the sides of the border default to [BorderSide.none].
  ///
  /// The arguments must not be null.
  const BorderDirectional({
    this.top = BorderSide.none,
    this.start = BorderSide.none,
    this.end = BorderSide.none,
    this.bottom = BorderSide.none,
  })  : assert(top != null),
        assert(start != null),
        assert(end != null),
        assert(bottom != null);
}

/// Base class for box borders that can paint as rectangles, circles, or rounded
/// rectangles.
///
/// This class is extended by [Border] and [BorderDirectional] to provide
/// concrete versions of four-sided borders using different conventions for
/// specifying the sides.
///
/// The only API difference that this class introduces over [ShapeBorder] is
/// that its [paint] method takes additional arguments.
///
/// See also:
///
///  * [BorderSide], which is used to describe each side of the box.
///  * [RoundedRectangleBorder], another way of describing a box's border.
///  * [CircleBorder], another way of describing a circle border.
///  * [BoxDecoration], which uses a [BoxBorder] to describe its borders.
abstract class BoxBorder extends ShapeBorder {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const BoxBorder();

  /// The bottom side of this border.
  BorderSide get bottom;

  /// The top side of this border.
  ///
  /// This getter is available on both [Border] and [BorderDirectional]. If
  /// [isUniform] is true, then this is the same style as all the other sides.
  BorderSide get top;
}

/// The shape to use when rendering a [Border] or [BoxDecoration].
///
/// Consider using [ShapeBorder] subclasses directly (with [ShapeDecoration]),
/// instead of using [BoxShape] and [Border], if the shapes will need to be
/// interpolated or animated. The [Border] class cannot interpolate between
/// different shapes.
enum BoxShape {
  /// An axis-aligned, 2D rectangle. May have rounded corners (described by a
  /// [BorderRadius]). The edges of the rectangle will match the edges of the box
  /// into which the [Border] or [BoxDecoration] is painted.
  ///
  /// See also:
  ///
  ///  * [RoundedRectangleBorder], the equivalent [ShapeBorder].
  rectangle,

  /// A circle centered in the middle of the box into which the [Border] or
  /// [BoxDecoration] is painted. The diameter of the circle is the shortest
  /// dimension of the box, either the width or the height, such that the circle
  /// touches the edges of the box.
  ///
  /// See also:
  ///
  ///  * [CircleBorder], the equivalent [ShapeBorder].
  circle,

  // Don't add more, instead create a new ShapeBorder.
}
