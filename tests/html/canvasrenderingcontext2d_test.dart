// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library url_test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  var canvas = new CanvasElement();
  canvas.width = 100;
  canvas.height = 100;

  var context = canvas.context2d;

  Uint8ClampedArray readPixel() {
    var imageData = context.getImageData(2, 2, 1, 1);
    return imageData.data;
  }

  test('setFillColorRgb', () {
    context.setFillColorRgb(255, 0, 255, 1);
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [255, 0, 255, 255]);
  });

  test('setFillColorHsl hue', () {
    context.setFillColorHsl(0, 100, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [255, 0, 0, 255]);
  });

  test('setFillColorHsl hue 2', () {
    context.setFillColorHsl(240, 100, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [0, 0, 255, 255]);
  });

  test('setFillColorHsl sat', () {
    context.setFillColorHsl(0, 0, 50);
    context.fillRect(0, 0, canvas.width, canvas.height);
    var pixel = readPixel();
    // Some rounding errors in the browsers.
    expect(pixel[0], closeTo(127, 1));
    expect(pixel[1], closeTo(127, 1));
    expect(pixel[2], closeTo(127, 1));
    expect(pixel[3], 255);
  });

  test('setStrokeColorRgb', () {
    context.setStrokeColorRgb(255, 0, 255, 1);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [255, 0, 255, 255]);
  });

  test('setStrokeColorHsl hue', () {
    context.setStrokeColorHsl(0, 100, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [255, 0, 0, 255]);
  });

  test('setStrokeColorHsl hue 2', () {
    context.setStrokeColorHsl(240, 100, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [0, 0, 255, 255]);
  });

  test('setStrokeColorHsl sat', () {
    context.setStrokeColorHsl(0, 0, 50);
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    var pixel = readPixel();
    // Some rounding errors in the browsers.
    expect(pixel[0], closeTo(127, 1));
    expect(pixel[1], closeTo(127, 1));
    expect(pixel[2], closeTo(127, 1));
    expect(pixel[3], 255);
  });

  test('fillStyle', () {
    context.fillStyle = "red";
    context.fillRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [255, 0, 0, 255]);
  });

  test('strokeStyle', () {
    context.strokeStyle = "blue";
    context.lineWidth = 10;
    context.strokeRect(0, 0, canvas.width, canvas.height);
    expect(readPixel(), [0, 0, 255, 255]);
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
    expectedData.data[2] = 255;
    context.fillStyle = 'green';
    context.fillRect(0, 0, canvas.width, canvas.height);

    context.putImageData(expectedData, 0, 0);

    var resultingData = context.getImageData(0, 0, 10, 10);
    // Make sure that we read back what we wrote.
    expect(resultingData.data, expectedData.data);
  });
}
