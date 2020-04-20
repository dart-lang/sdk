// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'basic_types.dart';

/// An immutable set of radii for each corner of a rectangle.
///
/// Used by [BoxDecoration] when the shape is a [BoxShape.rectangle].
///
/// The [BorderRadius] class specifies offsets in terms of visual corners, e.g.
/// [topLeft]. These values are not affected by the [TextDirection]. To support
/// both left-to-right and right-to-left layouts, consider using
/// [BorderRadiusDirectional], which is expressed in terms that are relative to
/// a [TextDirection] (typically obtained from the ambient [Directionality]).
class BorderRadius extends BorderRadiusGeometry {
  /// A border radius with all zero radii.
  static const BorderRadius zero = BorderRadius.all(Radius.zero);

  /// The top-left [Radius].
  final Radius topLeft;

  /// The top-right [Radius].
  final Radius topRight;

  /// The bottom-left [Radius].
  final Radius bottomLeft;

  /// The bottom-right [Radius].
  final Radius bottomRight;

  /// Creates a border radius where all radii are [radius].
  const BorderRadius.all(Radius radius)
      : this.only(
          topLeft: radius,
          topRight: radius,
          bottomLeft: radius,
          bottomRight: radius,
        );

  /// Creates a border radius where all radii are [Radius.circular(radius)].
  BorderRadius.circular(double radius)
      : this.all(
          Radius.circular(radius),
        );

  /// Creates a horizontally symmetrical border radius where the left and right
  /// sides of the rectangle have the same radii.
  const BorderRadius.horizontal({
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) : this.only(
          topLeft: left,
          topRight: right,
          bottomLeft: left,
          bottomRight: right,
        );

  /// Creates a border radius with only the given non-zero values. The other
  /// corners will be right angles.
  const BorderRadius.only({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });

  /// Creates a vertically symmetric border radius where the top and bottom
  /// sides of the rectangle have the same radii.
  const BorderRadius.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : this.only(
          topLeft: top,
          topRight: top,
          bottomLeft: bottom,
          bottomRight: bottom,
        );
}

/// An immutable set of radii for each corner of a rectangle, but with the
/// corners specified in a manner dependent on the writing direction.
///
/// This can be used to specify a corner radius on the leading or trailing edge
/// of a box, so that it flips to the other side when the text alignment flips
/// (e.g. being on the top right in English text but the top left in Arabic
/// text).
///
/// See also:
///
///  * [BorderRadius], a variant that uses physical labels (`topLeft` and
///    `topRight` instead of `topStart` and `topEnd`).
class BorderRadiusDirectional extends BorderRadiusGeometry {
  /// A border radius with all zero radii.
  ///
  /// Consider using [EdgeInsets.zero] instead, since that object has the same
  /// effect, but will be cheaper to [resolve].
  static const BorderRadiusDirectional zero =
      BorderRadiusDirectional.all(Radius.zero);

  /// The top-start [Radius].
  final Radius topStart;

  /// The top-end [Radius].
  final Radius topEnd;

  /// The bottom-start [Radius].
  final Radius bottomStart;

  /// The bottom-end [Radius].
  final Radius bottomEnd;

  /// Creates a border radius where all radii are [radius].
  const BorderRadiusDirectional.all(Radius radius)
      : this.only(
          topStart: radius,
          topEnd: radius,
          bottomStart: radius,
          bottomEnd: radius,
        );

  /// Creates a border radius where all radii are [Radius.circular(radius)].
  BorderRadiusDirectional.circular(double radius)
      : this.all(
          Radius.circular(radius),
        );

  /// Creates a horizontally symmetrical border radius where the start and end
  /// sides of the rectangle have the same radii.
  const BorderRadiusDirectional.horizontal({
    Radius start = Radius.zero,
    Radius end = Radius.zero,
  }) : this.only(
          topStart: start,
          topEnd: end,
          bottomStart: start,
          bottomEnd: end,
        );

  /// Creates a border radius with only the given non-zero values. The other
  /// corners will be right angles.
  const BorderRadiusDirectional.only({
    this.topStart = Radius.zero,
    this.topEnd = Radius.zero,
    this.bottomStart = Radius.zero,
    this.bottomEnd = Radius.zero,
  });

  /// Creates a vertically symmetric border radius where the top and bottom
  /// sides of the rectangle have the same radii.
  const BorderRadiusDirectional.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : this.only(
          topStart: top,
          topEnd: top,
          bottomStart: bottom,
          bottomEnd: bottom,
        );
}

/// Base class for [BorderRadius] that allows for text-direction aware resolution.
///
/// A property or argument of this type accepts classes created either with [new
/// BorderRadius.only] and its variants, or [new BorderRadiusDirectional.only]
/// and its variants.
///
/// To convert a [BorderRadiusGeometry] object of indeterminate type into a
/// [BorderRadius] object, call the [resolve] method.
@immutable
abstract class BorderRadiusGeometry {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const BorderRadiusGeometry();
}
