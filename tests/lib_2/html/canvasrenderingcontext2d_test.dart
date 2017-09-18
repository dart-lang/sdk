// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library canvas_rendering_context_2d_test;

import 'dart:html';
import 'dart:math';

import 'package:test/test.dart';

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

main() {
  group('pixel_manipulation', () {
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
  });

  group('arc', () {
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
      context.arc(cx, cy, r, 0, PI / 2);

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
      expectPixelFilled(
          (cx + r / SQRT2).toInt(), (cy + r / SQRT2).toInt(), true);

      // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
      expectPixelFilled(
          (cx - r / SQRT2).toInt(), (cy + r / SQRT2).toInt(), false);

      // (cx + r/SQRT2, cy + r/SQRT2) should be empty.
      expectPixelFilled(
          (cx - r / SQRT2).toInt(), (cy - r / SQRT2).toInt(), false);

      // (cx - r/SQRT2, cy - r/SQRT2) should be empty.
      expectPixelFilled(
          (cx + r / SQRT2).toInt(), (cy - r / SQRT2).toInt(), false);
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
      context.arc(cx, cy, r, .1, PI / 2 - .1, true);

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
          (cx + r / SQRT2).toInt(), (cy + r / SQRT2).toInt(), false);

      // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
      expectPixelFilled(
          (cx - r / SQRT2).toInt(), (cy + r / SQRT2).toInt(), true);

      // (cx + r/SQRT2, cy + r/SQRT2) should be filled.
      expectPixelFilled(
          (cx - r / SQRT2).toInt(), (cy - r / SQRT2).toInt(), true);

      // (cx - r/SQRT2, cy - r/SQRT2) should be filled.
      expectPixelFilled(
          (cx + r / SQRT2).toInt(), (cy - r / SQRT2).toInt(), true);
    });
  });

  group('drawImage_image_element', () {
    setUp(setupFunc);
    tearDown(tearDownFunc);
    // Draw an image to the canvas from an image element.
    test('with 3 params', () {
      var dataUrl = otherCanvas.toDataUrl('image/gif');
      var img = new ImageElement();

      img.onLoad.listen(expectAsync((_) {
        context.drawImage(img, 50, 50);

        expectPixelFilled(50, 50);
        expectPixelFilled(55, 55);
        expectPixelFilled(59, 59);
        expectPixelUnfilled(60, 60);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(70, 70);
      }));
      img.onError.listen((_) {
        fail('URL failed to load.');
      });
      img.src = dataUrl;
    });

    // Draw an image to the canvas from an image element and scale it.
    test('with 5 params', () {
      var dataUrl = otherCanvas.toDataUrl('image/gif');
      var img = new ImageElement();

      img.onLoad.listen(expectAsync((_) {
        context.drawImageToRect(img, new Rectangle(50, 50, 20, 20));

        expectPixelFilled(50, 50);
        expectPixelFilled(55, 55);
        expectPixelFilled(59, 59);
        expectPixelFilled(60, 60);
        expectPixelFilled(69, 69);
        expectPixelUnfilled(70, 70);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(80, 80);
      }));
      img.onError.listen((_) {
        fail('URL failed to load.');
      });
      img.src = dataUrl;
    });

    // Draw an image to the canvas from an image element and scale it.
    test('with 9 params', () {
      otherContext.fillStyle = "blue";
      otherContext.fillRect(5, 5, 5, 5);
      var dataUrl = otherCanvas.toDataUrl('image/gif');
      var img = new ImageElement();

      img.onLoad.listen(expectAsync((_) {
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
      }));
      img.onError.listen((_) {
        fail('URL failed to load.');
      });
      img.src = dataUrl;
    });
  });

  // These videos and base64 strings are the same video, representing 2
  // frames of 8x8 red pixels.
  // The videos were created with:
  //   convert -size 8x8 xc:red blank1.jpg
  //   convert -size 8x8 xc:red blank2.jpg
  //   avconv -f image2  -i "blank%d.jpg" -c:v libx264 small.mp4
  //   avconv -i small.mp4 small.webm
  //   python -m base64 -e small.mp4
  //   python -m base64 -e small.webm
  var mp4VideoUrl = '/root_dart/tests/html/small.mp4';
  var webmVideoUrl = '/root_dart/tests/html/small.webm';
  var mp4VideoDataUrl =
      'data:video/mp4;base64,AAAAIGZ0eXBpc29tAAACAGlzb21pc28yYXZjMW1wNDEAAA'
      'AIZnJlZQAAAsdtZGF0AAACmwYF//+X3EXpvebZSLeWLNgg2SPu73gyNjQgLSBjb3JlID'
      'EyMCByMjE1MSBhM2Y0NDA3IC0gSC4yNjQvTVBFRy00IEFWQyBjb2RlYyAtIENvcHlsZW'
      'Z0IDIwMDMtMjAxMSAtIGh0dHA6Ly93d3cudmlkZW9sYW4ub3JnL3gyNjQuaHRtbCAtIG'
      '9wdGlvbnM6IGNhYmFjPTEgcmVmPTMgZGVibG9jaz0xOjA6MCBhbmFseXNlPTB4MToweD'
      'ExMSBtZT1oZXggc3VibWU9NyBwc3k9MSBwc3lfcmQ9MS4wMDowLjAwIG1peGVkX3JlZj'
      '0wIG1lX3JhbmdlPTE2IGNocm9tYV9tZT0xIHRyZWxsaXM9MSA4eDhkY3Q9MCBjcW09MC'
      'BkZWFkem9uZT0yMSwxMSBmYXN0X3Bza2lwPTEgY2hyb21hX3FwX29mZnNldD0tMiB0aH'
      'JlYWRzPTE4IHNsaWNlZF90aHJlYWRzPTAgbnI9MCBkZWNpbWF0ZT0xIGludGVybGFjZW'
      'Q9MCBibHVyYXlfY29tcGF0PTAgY29uc3RyYWluZWRfaW50cmE9MCBiZnJhbWVzPTMgYl'
      '9weXJhbWlkPTAgYl9hZGFwdD0xIGJfYmlhcz0wIGRpcmVjdD0xIHdlaWdodGI9MCBvcG'
      'VuX2dvcD0xIHdlaWdodHA9MiBrZXlpbnQ9MjUwIGtleWludF9taW49MjUgc2NlbmVjdX'
      'Q9NDAgaW50cmFfcmVmcmVzaD0wIHJjX2xvb2thaGVhZD00MCByYz1jcmYgbWJ0cmVlPT'
      'EgY3JmPTUxLjAgcWNvbXA9MC42MCBxcG1pbj0wIHFwbWF4PTY5IHFwc3RlcD00IGlwX3'
      'JhdGlvPTEuMjUgYXE9MToxLjAwAIAAAAARZYiEB//3aoK5/tP9+8yeuIEAAAAHQZoi2P'
      '/wgAAAAzxtb292AAAAbG12aGQAAAAAAAAAAAAAAAAAAAPoAAAAUAABAAABAAAAAAAAAA'
      'AAAAAAAQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAACAAAAGGlvZHMAAAAAEICAgAcAT/////7/AAACUHRyYWsAAA'
      'BcdGtoZAAAAA8AAAAAAAAAAAAAAAEAAAAAAAAAUAAAAAAAAAAAAAAAAAAAAAAAAQAAAA'
      'AAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAEAAAAAACAAAAAgAAAAAACRlZHRzAAAAHG'
      'Vsc3QAAAAAAAAAAQAAAFAAAAABAAEAAAAAAchtZGlhAAAAIG1kaGQAAAAAAAAAAAAAAA'
      'AAAAAZAAAAAlXEAAAAAAAtaGRscgAAAAAAAAAAdmlkZQAAAAAAAAAAAAAAAFZpZGVvSG'
      'FuZGxlcgAAAAFzbWluZgAAABR2bWhkAAAAAQAAAAAAAAAAAAAAJGRpbmYAAAAcZHJlZg'
      'AAAAAAAAABAAAADHVybCAAAAABAAABM3N0YmwAAACXc3RzZAAAAAAAAAABAAAAh2F2Yz'
      'EAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAACAAIAEgAAABIAAAAAAAAAAEAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY//8AAAAxYXZjQwFNQAr/4QAYZ01ACuiPyy'
      '4C2QAAAwABAAADADIPEiUSAQAGaOvAZSyAAAAAGHN0dHMAAAAAAAAAAQAAAAIAAAABAA'
      'AAFHN0c3MAAAAAAAAAAQAAAAEAAAAYY3R0cwAAAAAAAAABAAAAAgAAAAEAAAAcc3RzYw'
      'AAAAAAAAABAAAAAQAAAAEAAAABAAAAHHN0c3oAAAAAAAAAAAAAAAIAAAK0AAAACwAAAB'
      'hzdGNvAAAAAAAAAAIAAAAwAAAC5AAAAGB1ZHRhAAAAWG1ldGEAAAAAAAAAIWhkbHIAAA'
      'AAAAAAAG1kaXJhcHBsAAAAAAAAAAAAAAAAK2lsc3QAAAAjqXRvbwAAABtkYXRhAAAAAQ'
      'AAAABMYXZmNTMuMjEuMQ==';
  var webmVideoDataUrl =
      'data:video/webm;base64,GkXfowEAAAAAAAAfQoaBAUL3gQFC8oEEQvOBCEKChHdlY'
      'm1Ch4ECQoWBAhhTgGcBAAAAAAAB/hFNm3RALE27i1OrhBVJqWZTrIHfTbuMU6uEFlSua'
      '1OsggEsTbuMU6uEHFO7a1OsggHk7AEAAAAAAACkAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAVSalmAQAAAAAAA'
      'EEq17GDD0JATYCLTGF2ZjUzLjIxLjFXQYtMYXZmNTMuMjEuMXOkkJatuHwTJ7cvFLSzB'
      'Smxbp5EiYhAVAAAAAAAABZUrmsBAAAAAAAAR64BAAAAAAAAPteBAXPFgQGcgQAitZyDd'
      'W5khoVWX1ZQOIOBASPjg4QCYloA4AEAAAAAAAASsIEIuoEIVLCBCFS6gQhUsoEDH0O2d'
      'QEAAAAAAABZ54EAo72BAACA8AIAnQEqCAAIAABHCIWFiIWEiAICAnWqA/gD+gINTRgA/'
      'v0hRf/kb+PnRv/I4//8WE8DijI//FRAo5WBACgAsQEAARAQABgAGFgv9AAIAAAcU7trA'
      'QAAAAAAAA67jLOBALeH94EB8YIBfw==';
  group('drawImage_video_element', () {
    setUp(setupFunc);
    tearDown(tearDownFunc);

    test('with 3 params', () {
      video.onCanPlay.listen(expectAsync((_) {
        context.drawImage(video, 50, 50);

        expectPixelFilled(50, 50);
        expectPixelFilled(54, 54);
        expectPixelFilled(57, 57);
        expectPixelUnfilled(58, 58);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(70, 70);
      }));

      video.onError.listen((_) {
        fail('URL failed to load.');
      });

      if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
        video.src = webmVideoUrl;
      } else if (video.canPlayType(
              'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
          '') {
        video.src = mp4VideoUrl;
      } else {
        window.console.log('Video is not supported on this system.');
      }
    });

    test('with 5 params', () {
      video.onCanPlay.listen(expectAsync((_) {
        context.drawImageToRect(video, new Rectangle(50, 50, 20, 20));

        expectPixelFilled(50, 50);
        expectPixelFilled(55, 55);
        expectPixelFilled(59, 59);
        expectPixelFilled(60, 60);
        expectPixelFilled(69, 69);
        expectPixelUnfilled(70, 70);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(80, 80);
      }));
      video.onError.listen((_) {
        fail('URL failed to load.');
      });

      if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
        video.src = webmVideoUrl;
      } else if (video.canPlayType(
              'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
          '') {
        video.src = mp4VideoUrl;
      } else {
        // TODO(amouravski): Better fallback?
        window.console.log('Video is not supported on this system.');
      }
    });

    test('with 9 params', () {
      video.onCanPlay.listen(expectAsync((_) {
        context.drawImageToRect(video, new Rectangle(50, 50, 20, 20),
            sourceRect: new Rectangle(2, 2, 6, 6));

        expectPixelFilled(50, 50);
        expectPixelFilled(55, 55);
        expectPixelFilled(59, 59);
        expectPixelFilled(60, 60);
        expectPixelFilled(69, 69);
        expectPixelUnfilled(70, 70);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(80, 80);
      }));
      video.onError.listen((_) {
        fail('URL failed to load.');
      });

      if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
        video.src = webmVideoUrl;
      } else if (video.canPlayType(
              'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
          '') {
        video.src = mp4VideoUrl;
      } else {
        // TODO(amouravski): Better fallback?
        window.console.log('Video is not supported on this system.');
      }
    });
  });

  group('drawImage_video_element_dataUrl', () {
    setUp(setupFunc);
    tearDown(tearDownFunc);

    test('with 9 params', () {
      video = new VideoElement();
      canvas = new CanvasElement();
      video.onCanPlay.listen(expectAsync((_) {
        context.drawImageToRect(video, new Rectangle(50, 50, 20, 20),
            sourceRect: new Rectangle(2, 2, 6, 6));

        expectPixelFilled(50, 50);
        expectPixelFilled(55, 55);
        expectPixelFilled(59, 59);
        expectPixelFilled(60, 60);
        expectPixelFilled(69, 69);
        expectPixelUnfilled(70, 70);
        expectPixelUnfilled(0, 0);
        expectPixelUnfilled(80, 80);
      }));
      video.onError.listen((_) {
        fail('URL failed to load.');
      });

      if (video.canPlayType('video/webm; codecs="vp8.0, vorbis"', '') != '') {
        video.src = webmVideoDataUrl;
      } else if (video.canPlayType(
              'video/mp4; codecs="avc1.4D401E, mp4a.40.2"', null) !=
          '') {
        video.src = mp4VideoDataUrl;
      } else {
        // TODO(amouravski): Better fallback?
        window.console.log('Video is not supported on this system.');
      }
    });
  });

  group('drawImage_canvas_element', () {
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
  });

  group('fillText', () {
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
  });
}
