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

  test('with 3 params', () {
    // Draw an image to the canvas from a canvas element.
    context.drawImage(otherCanvas, 50, 50);

    expectPixelFilled(50, 50);
    expectPixelFilled(55, 55);
    expectPixelFilled(59, 59);
    expectPixelUnfilled(60, 60);
    expectPixelUnfilled(0, 0);
    expectPixelUnfilled(70, 70);
  });
  test('with 5 params', () {
    // Draw an image to the canvas from a canvas element.
    context.drawImageToRect(otherCanvas, new Rectangle(50, 50, 20, 20));

    expectPixelFilled(50, 50);
    expectPixelFilled(55, 55);
    expectPixelFilled(59, 59);
    expectPixelFilled(60, 60);
    expectPixelFilled(69, 69);
    expectPixelUnfilled(70, 70);
    expectPixelUnfilled(0, 0);
    expectPixelUnfilled(80, 80);
  });
  test('with 9 params', () {
    // Draw an image to the canvas from a canvas element.
    otherContext.fillStyle = "blue";
    otherContext.fillRect(5, 5, 5, 5);
    context.drawImageToRect(otherCanvas, new Rectangle(50, 50, 20, 20),
        sourceRect: new Rectangle(2, 2, 6, 6));

    checkPixel(readPixel(50, 50), [255, 0, 0, 255]);
    checkPixel(readPixel(55, 55), [255, 0, 0, 255]);
    checkPixel(readPixel(60, 50), [255, 0, 0, 255]);
    checkPixel(readPixel(65, 65), [0, 0, 255, 255]);
    checkPixel(readPixel(69, 69), [0, 0, 255, 255]);
    expectPixelFilled(50, 50);
    expectPixelFilled(55, 55);
    expectPixelFilled(59, 59);
    expectPixelFilled(60, 60);
    expectPixelFilled(69, 69);
    expectPixelUnfilled(70, 70);
    expectPixelUnfilled(0, 0);
    expectPixelUnfilled(80, 80);
  });

  test('createImageData', () {
    var imageData = context.createImageData(15, 15);
    expect(imageData.width, 15);
    expect(imageData.height, 15);

    var other = context.createImageDataFromImageData(imageData);
    expect(other.width, 15);
    expect(other.height, 15);
  });

  test('createPattern', () {
    var pattern = context.createPattern(new CanvasElement(), '');
    //var pattern2 = context.createPatternFromImage(new ImageElement(), '');
  });
}
