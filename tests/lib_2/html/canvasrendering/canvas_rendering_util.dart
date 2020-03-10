// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canvas_rendering_context_2d_test;

import 'dart:html';
import 'dart:math';

import 'package:expect/minitest.dart';

// Some rounding errors in the browsers.
checkPixel(List<int> pixel, List<int> expected) {
  expect(pixel[0], closeTo(expected[0], 2));
  expect(pixel[1], closeTo(expected[1], 2));
  expect(pixel[2], closeTo(expected[2], 2));
  expect(pixel[3], closeTo(expected[3], 2));
}

var canvas;
var context;
var otherCanvas;
var otherContext;
var video;

void createCanvas() {
  canvas = new CanvasElement();
  canvas.width = 100;
  canvas.height = 100;

  context = canvas.context2D;
}

void createOtherCanvas() {
  otherCanvas = new CanvasElement();
  otherCanvas.width = 10;
  otherCanvas.height = 10;
  otherContext = otherCanvas.context2D;
  otherContext.fillStyle = "red";
  otherContext.fillRect(0, 0, otherCanvas.width, otherCanvas.height);
}

void setupFunc() {
  createCanvas();
  createOtherCanvas();
  video = new VideoElement();
}

void tearDownFunc() {
  canvas = null;
  context = null;
  otherCanvas = null;
  otherContext = null;
  video = null;
}

List<int> readPixel(int x, int y) {
  var imageData = context.getImageData(x, y, 1, 1);
  return imageData.data;
}

/// Returns true if the pixel has some data in it, false otherwise.
bool isPixelFilled(int x, int y) => readPixel(x, y).any((p) => p != 0);

String pixelDataToString(List<int> data, int x, int y) {
  return '[${data.join(", ")}]';
}

String _filled(bool v) => v ? "filled" : "unfilled";

void expectPixelFilled(int x, int y, [bool filled = true]) {
  expect(isPixelFilled(x, y), filled,
      reason: 'Pixel at ($x, $y) was expected to'
          ' be: <${_filled(filled)}> but was: <${_filled(!filled)}> with data: '
          '${pixelDataToString(readPixel(x, y), x, y)}');
}

void expectPixelUnfilled(int x, int y) {
  expectPixelFilled(x, y, false);
}
