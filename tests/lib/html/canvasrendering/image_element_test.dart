// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canvas_rendering_context_2d_test;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'canvas_rendering_util.dart';
import 'package:async_helper/async_helper.dart';

Future testWithThreeParams() async {
  setupFunc();
  // Draw an image to the canvas from an image element.
  var dataUrl = otherCanvas.toDataUrl('image/gif');
  var img = new ImageElement();

  var loadedFuture = img.onLoad.first;
  img.onError.listen((_) {
    throw ('URL failed to load.');
  });
  img.src = dataUrl;

  await loadedFuture;
  context.drawImage(img, 50, 50);

  expectPixelFilled(50, 50);
  expectPixelFilled(55, 55);
  expectPixelFilled(59, 59);
  expectPixelUnfilled(60, 60);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(70, 70);
  tearDownFunc();
}

Future testWithFiveParams() async {
  setupFunc();
  // Draw an image to the canvas from an image element and scale it.
  var dataUrl = otherCanvas.toDataUrl('image/gif');
  var img = new ImageElement();

  var loadedFuture = img.onLoad.first;
  img.onError.listen((_) {
    throw ('URL failed to load.');
  });
  img.src = dataUrl;

  await loadedFuture;
  context.drawImageToRect(img, new Rectangle(50, 50, 20, 20));

  expectPixelFilled(50, 50);
  expectPixelFilled(55, 55);
  expectPixelFilled(59, 59);
  expectPixelFilled(60, 60);
  expectPixelFilled(69, 69);
  expectPixelUnfilled(70, 70);
  expectPixelUnfilled(0, 0);
  expectPixelUnfilled(80, 80);
  tearDownFunc();
}

Future testWithNineParams() async {
  setupFunc();
  // Draw an image to the canvas from an image element and scale it.
  otherContext.fillStyle = "blue";
  otherContext.fillRect(5, 5, 5, 5);
  var dataUrl = otherCanvas.toDataUrl('image/gif');
  var img = new ImageElement();

  var loadedFuture = img.onLoad.first;
  img.onError.listen((_) {
    throw ('URL failed to load.');
  });
  img.src = dataUrl;

  await loadedFuture;
  // This will take a 6x6 square from the first canvas from position 2,2
  // and then scale it to a 20x20 square and place it to the second
  // canvas at 50,50.
  context.drawImageToRect(img, new Rectangle(50, 50, 20, 20),
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
  tearDownFunc();
}

main() {
  asyncTest(() async {
    await testWithThreeParams();
    await testWithFiveParams();
    await testWithNineParams();
  });
}
