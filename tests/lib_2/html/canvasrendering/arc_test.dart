// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canvas_rendering_context_2d_test;

import 'dart:html';
import 'dart:math';

import 'canvas_rendering_util.dart';
import 'package:expect/minitest.dart';

main() {
  setUp(setupFunc);
  tearDown(tearDownFunc);

  test('default arc should be clockwise', () {
    context.beginPath();
    final r = 10;

    // Center of arc.
    final cx = 20;
    final cy = 20;
    // Arc centered at (20, 20) with radius 10 will go clockwise
    // from (20 + r, 20) to (20, 20 + r), which is 1/4 of a circle.
    context.arc(cx, cy, r, 0, pi / 2);

    context.strokeStyle = 'green';
    context.lineWidth = 2;
    context.stroke();

    // Center should not be filled.
    expectPixelUnfilled(cx, cy);

    // (cx + r, cy) should be filled.
    expectPixelFilled(cx + r, cy, true);
    // (cx, cy + r) should be filled.
    expectPixelFilled(cx, cy + r, true);
    // (cx - r, cy) should be empty.
    expectPixelFilled(cx - r, cy, false);
    // (cx, cy - r) should be empty.
    expectPixelFilled(cx, cy - r, false);

    // (cx + r/SQRT2, cy + r/SQRT2) should be filled.
    expectPixelFilled((cx + r / sqrt2).toInt(), (cy + r / sqrt2).toInt(), true);

    // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
    expectPixelFilled(
        (cx - r / sqrt2).toInt(), (cy + r / sqrt2).toInt(), false);

    // (cx + r/SQRT2, cy + r/SQRT2) should be empty.
    expectPixelFilled(
        (cx - r / sqrt2).toInt(), (cy - r / sqrt2).toInt(), false);

    // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
    expectPixelFilled(
        (cx + r / sqrt2).toInt(), (cy - r / sqrt2).toInt(), false);
  });

  test('arc anticlockwise', () {
    context.beginPath();
    final r = 10;

    // Center of arc.
    final cx = 20;
    final cy = 20;
    // Arc centered at (20, 20) with radius 10 will go anticlockwise
    // from (20 + r, 20) to (20, 20 + r), which is 3/4 of a circle.
    // Because of the way arc work, when going anti-clockwise, the end points
    // are not included, so small values are added to radius to make a little
    // more than a 3/4 circle.
    context.arc(cx, cy, r, .1, pi / 2 - .1, true);

    context.strokeStyle = 'green';
    context.lineWidth = 2;
    context.stroke();

    // Center should not be filled.
    expectPixelUnfilled(cx, cy);

    // (cx + r, cy) should be filled.
    expectPixelFilled(cx + r, cy, true);
    // (cx, cy + r) should be filled.
    expectPixelFilled(cx, cy + r, true);
    // (cx - r, cy) should be filled.
    expectPixelFilled(cx - r, cy, true);
    // (cx, cy - r) should be filled.
    expectPixelFilled(cx, cy - r, true);

    // (cx + r/SQRT2, cy + r/SQRT2) should be empty.
    expectPixelFilled(
        (cx + r / sqrt2).toInt(), (cy + r / sqrt2).toInt(), false);

    // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
    expectPixelFilled((cx - r / sqrt2).toInt(), (cy + r / sqrt2).toInt(), true);

    // (cx + r/SQRT2, cy + r/SQRT2) should be filled.
    expectPixelFilled((cx - r / sqrt2).toInt(), (cy - r / sqrt2).toInt(), true);

    // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
    expectPixelFilled((cx + r / sqrt2).toInt(), (cy - r / sqrt2).toInt(), true);
  });
}
