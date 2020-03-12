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

  final x = 20;
  final y = 20;

  test('without maxWidth', () {
    context.font = '40pt Garamond';
    context.fillStyle = 'blue';

    // Draw a blue box.
    context.fillText('█', x, y);

    var width = context.measureText('█').width.ceil();

    checkPixel(readPixel(x, y), [0, 0, 255, 255]);
    checkPixel(readPixel(x + 10, y), [0, 0, 255, 255]);

    expectPixelUnfilled(x - 10, y);
    expectPixelFilled(x, y);
    expectPixelFilled(x + 10, y);

    // The box does not draw after `width` pixels.
    // Check -2 rather than -1 because this seems
    // to run into a rounding error on Mac bots.
    expectPixelFilled(x + width - 2, y);
    expectPixelUnfilled(x + width + 1, y);
  });

  test('with maxWidth null', () {
    context.font = '40pt Garamond';
    context.fillStyle = 'blue';

    // Draw a blue box with null maxWidth.
    context.fillText('█', x, y, null);

    var width = context.measureText('█').width.ceil();

    checkPixel(readPixel(x, y), [0, 0, 255, 255]);
    checkPixel(readPixel(x + 10, y), [0, 0, 255, 255]);

    expectPixelUnfilled(x - 10, y);
    expectPixelFilled(x, y);
    expectPixelFilled(x + 10, y);

    // The box does not draw after `width` pixels.
    // Check -2 rather than -1 because this seems
    // to run into a rounding error on Mac bots.
    expectPixelFilled(x + width - 2, y);
    expectPixelUnfilled(x + width + 1, y);
  });

  test('with maxWidth defined', () {
    context.font = '40pt Garamond';
    context.fillStyle = 'blue';

    final maxWidth = 20;

    // Draw a blue box that's at most 20 pixels wide.
    context.fillText('█', x, y, maxWidth);

    checkPixel(readPixel(x, y), [0, 0, 255, 255]);
    checkPixel(readPixel(x + 10, y), [0, 0, 255, 255]);

    // The box does not draw after 20 pixels.
    expectPixelUnfilled(x - 10, y);
    expectPixelUnfilled(x + maxWidth + 1, y);
    expectPixelUnfilled(x + maxWidth + 20, y);
    expectPixelFilled(x, y);
    expectPixelFilled(x + 10, y);
  });
}
