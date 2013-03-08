// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library url_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:math';

// Some rounding errors in the browsers.
checkPixel(List<int> pixel, List<int> expected) {
  expect(pixel[0], closeTo(expected[0], 2));
  expect(pixel[1], closeTo(expected[1], 2));
  expect(pixel[2], closeTo(expected[2], 2));
  expect(pixel[3], closeTo(expected[3], 2));
}

main() {
  useHtmlConfiguration();

  group('canvasRenderingContext2d', () {
    var canvas;
    var context;

    setUp(() {
      canvas = new CanvasElement();
      canvas.width = 100;
      canvas.height = 100;

      context = canvas.context2d;
    });

    tearDown(() {
      canvas = null;
      context = null;
    });

    List<int> readPixel(int x, int y) {
      var imageData = context.getImageData(x, y, 1, 1);
      return imageData.data;
    }

    /// Returns true if the pixel has some data in it, false otherwise.
    bool isPixelFilled(int x, int y) => readPixel(x,y).any((p) => p != 0);

    String pixelDataToString(int x, int y) {
      var data = readPixel(x, y);

      return '[${data.join(", ")}]';
    }

    String _filled(bool v) => v ? "filled" : "unfilled";

    void expectPixelFilled(int x, int y, [bool filled = true]) {
      expect(isPixelFilled(x, y), filled, reason:
          'Pixel at ($x, $y) was expected to'
          ' be: <${_filled(filled)}> but was: <${_filled(!filled)}> with data: '
          '${pixelDataToString(x,y)}');
    }

    void expectPixelUnfilled(int x, int y) {
      expectPixelFilled(x, y, false);
    }


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
      var gradient = context.createLinearGradient(0,0,20,20);
      gradient.addColorStop(0,'red');
      gradient.addColorStop(1,'blue');
      context.fillStyle = gradient;
      context.fillRect(0, 0, canvas.width, canvas.height);
      expect(context.fillStyle is CanvasGradient, isTrue);
    });

    test('putImageData', () {
      ImageData expectedData = context.getImageData(0, 0, 10, 10);
      expectedData.data[0] = 25;
      expectedData.data[1] = 65;
      expectedData.data[2] = 255;
      // Set alpha to 255 to make the pixels show up.
      expectedData.data[3] = 255;
      context.fillStyle = 'green';
      context.fillRect(0, 0, canvas.width, canvas.height);

      context.putImageData(expectedData, 0, 0);

      var resultingData = context.getImageData(0, 0, 10, 10);
      // Make sure that we read back what we wrote.
      expect(resultingData.data, expectedData.data);
    });

    test('default arc should be clockwise', () {
      context.beginPath();
      final r = 10;

      // Center of arc.
      final cx = 20;
      final cy = 20;
      // Arc centered at (20, 20) with radius 10 will go clockwise
      // from (20 + r, 20) to (20, 20 + r), which is 1/4 of a circle.
      context.arc(cx, cy, r, 0, PI/2);

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
      expectPixelFilled(cx + r/SQRT2, cy + r/SQRT2, true);

      // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
      expectPixelFilled(cx - r/SQRT2, cy + r/SQRT2, false);

      // (cx + r/SQRT2, cy + r/SQRT2) should be empty.
      expectPixelFilled(cx - r/SQRT2, cy - r/SQRT2, false);

      // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
      expectPixelFilled(cx + r/SQRT2, cy - r/SQRT2, false);
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
      context.arc(cx, cy, r, .1, PI/2 - .1, true);

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
      expectPixelFilled(cx + r/SQRT2, cy + r/SQRT2, false);

      // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
      expectPixelFilled(cx - r/SQRT2, cy + r/SQRT2, true);

      // (cx + r/SQRT2, cy + r/SQRT2) should be filled.
      expectPixelFilled(cx - r/SQRT2, cy - r/SQRT2, true);

      // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
      expectPixelFilled(cx + r/SQRT2, cy - r/SQRT2, true);
    });
  });
}
