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

  test('setFillColorRgb', () {
    context.setFillColorRgb(255, 0, 255, 1);
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(2, 2), [255, 0, 255, 255]);
  });

  test('setFillColorHsl hue', () {
    context.setFillColorHsl(0, 100, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    checkPixel(readPixel(2, 2), [255, 0, 0, 255]);
  });

  test('setFillColorHsl hue 2', () {
    context.setFillColorHsl(240, 100, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    checkPixel(readPixel(2, 2), [0, 0, 255, 255]);
  });

  test('setFillColorHsl sat', () {
    context.setFillColorHsl(0, 0, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    checkPixel(readPixel(2, 2), [127, 127, 127, 255]);
  });

  test('setStrokeColorRgb', () {
    context.setStrokeColorRgb(255, 0, 255, 1);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(2, 2), [255, 0, 255, 255]);
  });

  test('setStrokeColorHsl hue', () {
    context.setStrokeColorHsl(0, 100, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(2, 2), [255, 0, 0, 255]);
  });

  test('setStrokeColorHsl hue 2', () {
    context.setStrokeColorHsl(240, 100, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(2, 2), [0, 0, 255, 255]);
  });

  test('setStrokeColorHsl sat', () {
    context.setStrokeColorHsl(0, 0, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    checkPixel(readPixel(2, 2), [127, 127, 127, 255]);
  });

  test('fillStyle', () {
    context.fillStyle = "red";
    context.fillRect(0, 0, canvas.width, canvas.height);
    checkPixel(readPixel(2, 2), [255, 0, 0, 255]);
  });

  test('strokeStyle', () {
    context.strokeStyle = "blue";
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(2, 2), [0, 0, 255, 255]);
  });

  test('fillStyle linearGradient', () {
    var gradient = context.createLinearGradient(0, 0, 20, 20);
    gradient.addColorStop(0, 'red');
    gradient.addColorStop(1, 'blue');
    context.fillStyle = gradient;
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(context.fillStyle is CanvasGradient, isTrue);
  });

  test('putImageData', () {
    context.fillStyle = 'green';
    context.fillRect(0, 0, canvas.width, canvas.height);

    ImageData expectedData = context.getImageData(0, 0, 10, 10);
    expectedData.data[0] = 25;
    expectedData.data[1] = 65;
    expectedData.data[2] = 255;
    // Set alpha to 255 to make the pixels show up.
    expectedData.data[3] = 255;

    context.putImageData(expectedData, 0, 0);

    var resultingData = context.getImageData(0, 0, 10, 10);
    // Make sure that we read back what we wrote.
    expect(resultingData.data, expectedData.data);
  });

  test('putImageData dirty rectangle', () {
    context.fillStyle = 'green';
    context.fillRect(0, 0, canvas.width, canvas.height);

    ImageData drawnData = context.getImageData(0, 0, 10, 10);
    drawnData.data[0] = 25;
    drawnData.data[1] = 65;
    drawnData.data[2] = 255;
    drawnData.data[3] = 255;

    // Draw these pixels to the 2nd pixel.
    drawnData.data[2 * 4 + 0] = 25;
    drawnData.data[2 * 4 + 1] = 65;
    drawnData.data[2 * 4 + 2] = 255;
    drawnData.data[2 * 4 + 3] = 255;

    // Draw these pixels to the 8th pixel.
    drawnData.data[7 * 4 + 0] = 25;
    drawnData.data[7 * 4 + 1] = 65;
    drawnData.data[7 * 4 + 2] = 255;
    drawnData.data[7 * 4 + 3] = 255;

    // Use a dirty rectangle to limit what pixels are drawn.
    context.putImageData(drawnData, 0, 0, 1, 0, 5, 5);

    // Expect the data to be all green, as we skip all drawn pixels.
    ImageData expectedData = context.createImageData(10, 10);
    for (int i = 0; i < expectedData.data.length; i++) {
      switch (i % 4) {
        case 0:
          expectedData.data[i] = 0;
          break;
        case 1:
          expectedData.data[i] = 128;
          break;
        case 2:
          expectedData.data[i] = 0;
          break;
        case 3:
          expectedData.data[i] = 255;
          break;
      }
    }
    // Third pixel was copied.
    expectedData.data[2 * 4 + 0] = 25;
    expectedData.data[2 * 4 + 1] = 65;
    expectedData.data[2 * 4 + 2] = 255;
    expectedData.data[2 * 4 + 3] = 255;

    // Make sure that our data is all green.
    var resultingData = context.getImageData(0, 0, 10, 10);
    expect(resultingData.data, expectedData.data);
  });

  test('putImageData throws with wrong number of arguments', () {
    ImageData expectedData = context.getImageData(0, 0, 10, 10);

    // TODO(antonm): in Dartium ArgumentError should be thrown too.
    expect(() => context.putImageData(expectedData, 0, 0, 1), throws);
    expect(() => context.putImageData(expectedData, 0, 0, 1, 1), throws);
    expect(() => context.putImageData(expectedData, 0, 0, 1, 1, 5), throws);
  });
}
