// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class EdgeInsets extends EdgeInsetsGeometry {
  /// An [EdgeInsets] with zero offsets in each direction.
  static const EdgeInsets zero = EdgeInsets.only();

  /// The offset from the left.
  final double left;

  /// The offset from the top.
  final double top;

  /// The offset from the right.
  final double right;

  /// The offset from the bottom.
  final double bottom;

  const EdgeInsets.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);

  const EdgeInsets.only({
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
  });

  const EdgeInsets.symmetric({
    double vertical = 0.0,
    double horizontal = 0.0,
  })  : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;
}

abstract class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();
}
