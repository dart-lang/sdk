// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// A point within a rectangle.
///
/// `Alignment(0.0, 0.0)` represents the center of the rectangle. The distance
/// from -1.0 to +1.0 is the distance from one side of the rectangle to the
/// other side of the rectangle. Therefore, 2.0 units horizontally (or
/// vertically) is equivalent to the width (or height) of the rectangle.
///
/// `Alignment(-1.0, -1.0)` represents the top left of the rectangle.
///
/// `Alignment(1.0, 1.0)` represents the bottom right of the rectangle.
///
/// `Alignment(0.0, 3.0)` represents a point that is horizontally centered with
/// respect to the rectangle and vertically below the bottom of the rectangle by
/// the height of the rectangle.
///
/// `Alignment(0.0, -0.5)` represents a point that is horizontally centered with
/// respect to the rectangle and vertically half way between the top edge and
/// the center.
///
/// `Alignment(x, y)` in a rectangle with height h and width w describes
/// the point (x * w/2 + w/2, y * h/2 + h/2) in the coordinate system of the
/// rectangle.
///
/// [Alignment] uses visual coordinates, which means increasing [x] moves the
/// point from left to right. To support layouts with a right-to-left
/// [TextDirection], consider using [AlignmentDirectional], in which the
/// direction the point moves when increasing the horizontal value depends on
/// the [TextDirection].
///
/// A variety of widgets use [Alignment] in their configuration, most
/// notably:
///
///  * [Align] positions a child according to an [Alignment].
///
/// See also:
///
///  * [AlignmentDirectional], which has a horizontal coordinate orientation
///    that depends on the [TextDirection].
///  * [AlignmentGeometry], which is an abstract type that is agnostic as to
///    whether the horizontal direction depends on the [TextDirection].
class Alignment extends AlignmentGeometry {
  /// The top left corner.
  static const Alignment topLeft = Alignment(-1.0, -1.0);

  /// The center point along the top edge.
  static const Alignment topCenter = Alignment(0.0, -1.0);

  /// The top right corner.
  static const Alignment topRight = Alignment(1.0, -1.0);

  /// The center point along the left edge.
  static const Alignment centerLeft = Alignment(-1.0, 0.0);

  /// The center point, both horizontally and vertically.
  static const Alignment center = Alignment(0.0, 0.0);

  /// The center point along the right edge.
  static const Alignment centerRight = Alignment(1.0, 0.0);

  /// The bottom left corner.
  static const Alignment bottomLeft = Alignment(-1.0, 1.0);

  /// The center point along the bottom edge.
  static const Alignment bottomCenter = Alignment(0.0, 1.0);

  /// The bottom right corner.
  static const Alignment bottomRight = Alignment(1.0, 1.0);

  /// The distance fraction in the horizontal direction.
  ///
  /// A value of -1.0 corresponds to the leftmost edge. A value of 1.0
  /// corresponds to the rightmost edge. Values are not limited to that range;
  /// values less than -1.0 represent positions to the left of the left edge,
  /// and values greater than 1.0 represent positions to the right of the right
  /// edge.
  final double x;

  /// The distance fraction in the vertical direction.
  ///
  /// A value of -1.0 corresponds to the topmost edge. A value of 1.0
  /// corresponds to the bottommost edge. Values are not limited to that range;
  /// values less than -1.0 represent positions above the top, and values
  /// greater than 1.0 represent positions below the bottom.
  final double y;

  /// Creates an alignment.
  ///
  /// The [x] and [y] arguments must not be null.
  const Alignment(this.x, this.y)
      : assert(x != null),
        assert(y != null);
}

/// An offset that's expressed as a fraction of a [Size], but whose horizontal
/// component is dependent on the writing direction.
///
/// This can be used to indicate an offset from the left in [TextDirection.ltr]
/// text and an offset from the right in [TextDirection.rtl] text without having
/// to be aware of the current text direction.
///
/// See also:
///
///  * [Alignment], a variant that is defined in physical terms (i.e.
///    whose horizontal component does not depend on the text direction).
class AlignmentDirectional extends AlignmentGeometry {
  /// The top corner on the "start" side.
  static const AlignmentDirectional topStart = AlignmentDirectional(-1.0, -1.0);

  /// The center point along the top edge.
  ///
  /// Consider using [Alignment.topCenter] instead, as it does not need
  /// to be [resolve]d to be used.
  static const AlignmentDirectional topCenter = AlignmentDirectional(0.0, -1.0);

  /// The top corner on the "end" side.
  static const AlignmentDirectional topEnd = AlignmentDirectional(1.0, -1.0);

  /// The center point along the "start" edge.
  static const AlignmentDirectional centerStart =
      AlignmentDirectional(-1.0, 0.0);

  /// The center point, both horizontally and vertically.
  ///
  /// Consider using [Alignment.center] instead, as it does not need to
  /// be [resolve]d to be used.
  static const AlignmentDirectional center = AlignmentDirectional(0.0, 0.0);

  /// The center point along the "end" edge.
  static const AlignmentDirectional centerEnd = AlignmentDirectional(1.0, 0.0);

  /// The bottom corner on the "start" side.
  static const AlignmentDirectional bottomStart =
      AlignmentDirectional(-1.0, 1.0);

  /// The center point along the bottom edge.
  ///
  /// Consider using [Alignment.bottomCenter] instead, as it does not
  /// need to be [resolve]d to be used.
  static const AlignmentDirectional bottomCenter =
      AlignmentDirectional(0.0, 1.0);

  /// The bottom corner on the "end" side.
  static const AlignmentDirectional bottomEnd = AlignmentDirectional(1.0, 1.0);

  /// The distance fraction in the horizontal direction.
  ///
  /// A value of -1.0 corresponds to the edge on the "start" side, which is the
  /// left side in [TextDirection.ltr] contexts and the right side in
  /// [TextDirection.rtl] contexts. A value of 1.0 corresponds to the opposite
  /// edge, the "end" side. Values are not limited to that range; values less
  /// than -1.0 represent positions beyond the start edge, and values greater than
  /// 1.0 represent positions beyond the end edge.
  ///
  /// This value is normalized into an [Alignment.x] value by the [resolve]
  /// method.
  final double start;

  /// The distance fraction in the vertical direction.
  ///
  /// A value of -1.0 corresponds to the topmost edge. A value of 1.0
  /// corresponds to the bottommost edge. Values are not limited to that range;
  /// values less than -1.0 represent positions above the top, and values
  /// greater than 1.0 represent positions below the bottom.
  ///
  /// This value is passed through to [Alignment.y] unmodified by the
  /// [resolve] method.
  final double y;

  /// Creates a directional alignment.
  ///
  /// The [start] and [y] arguments must not be null.
  const AlignmentDirectional(this.start, this.y)
      : assert(start != null),
        assert(y != null);
}

/// Base class for [Alignment] that allows for text-direction aware
/// resolution.
///
/// A property or argument of this type accepts classes created either with [new
/// Alignment] and its variants, or [new AlignmentDirectional].
///
/// To convert an [AlignmentGeometry] object of indeterminate type into an
/// [Alignment] object, call the [resolve] method.
@immutable
abstract class AlignmentGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const AlignmentGeometry();
}

/// The vertical alignment of text within an input box.
///
/// A single [y] value that can range from -1.0 to 1.0. -1.0 aligns to the top
/// of an input box so that the top of the first line of text fits within the
/// box and its padding. 0.0 aligns to the center of the box. 1.0 aligns so that
/// the bottom of the last line of text aligns with the bottom interior edge of
/// the input box.
///
/// See also:
///
///  * [TextField.textAlignVertical], which is passed on to the [InputDecorator].
///  * [CupertinoTextField.textAlignVertical], which behaves in the same way as
///    the parameter in TextField.
///  * [InputDecorator.textAlignVertical], which defines the alignment of
///    prefix, input, and suffix within an [InputDecorator].
class TextAlignVertical {
  /// Aligns a TextField's input Text with the topmost location within a
  /// TextField's input box.
  static const TextAlignVertical top = TextAlignVertical(y: -1.0);

  /// Aligns a TextField's input Text to the center of the TextField.
  static const TextAlignVertical center = TextAlignVertical(y: 0.0);

  /// Aligns a TextField's input Text with the bottommost location within a
  /// TextField.
  static const TextAlignVertical bottom = TextAlignVertical(y: 1.0);

  /// A value ranging from -1.0 to 1.0 that defines the topmost and bottommost
  /// locations of the top and bottom of the input box.
  final double y;

  /// Creates a TextAlignVertical from any y value between -1.0 and 1.0.
  const TextAlignVertical({
    @required this.y,
  })  : assert(y != null),
        assert(y >= -1.0 && y <= 1.0);

  @override
  String toString() {
    return '$runtimeType(y: $y)';
  }
}
