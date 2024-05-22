// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// A radius for either circular or elliptical shapes.
class Radius {
  /// A radius with [x] and [y] values set to zero.
  ///
  /// You can use [Radius.zero] with [RRect] to have right-angle corners.
  static const Radius zero = Radius.circular(0.0);

  /// The radius value on the horizontal axis.
  final double x;

  /// The radius value on the vertical axis.
  final double y;

  /// Constructs a circular radius. [x] and [y] will have the same radius value.
  const Radius.circular(double radius) : this.elliptical(radius, radius);

  /// Constructs an elliptical radius with the given radii.
  const Radius.elliptical(this.x, this.y);
}
