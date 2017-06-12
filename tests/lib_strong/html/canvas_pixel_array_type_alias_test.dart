// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

import 'dart:html';
import 'dart:typed_data';

import 'package:expect/minitest.dart';

// We have aliased the legacy type CanvasPixelArray with the new type
// Uint8ClampedArray by mapping the CanvasPixelArray type tag to
// Uint8ClampedArray.  It is not a perfect match since CanvasPixelArray is
// missing the ArrayBufferView members.  These should appear to be null.

var inscrutable;

main() {
  inscrutable = (x) => x;

  int width = 100;
  int height = 100;

  CanvasElement canvas = new CanvasElement(width: width, height: height);
  document.body.append(canvas);

  CanvasRenderingContext2D context = canvas.context2D;

  group('basic', () {
    test('CreateImageData', () {
      ImageData image = context.createImageData(canvas.width, canvas.height);
      List<int> data = image.data;
      // It is legal for the dart2js compiler to believe the type of the native
      //   ImageData.data and elides the check, so check the type explicitly:
      expect(inscrutable(data) is List<int>, isTrue,
          reason: 'canvas array type');

      expect(data.length, 40000);
      checkPixel(data, 0, [0, 0, 0, 0]);
      checkPixel(data, width * height - 1, [0, 0, 0, 0]);

      data[100] = 200;
      expect(data[100], equals(200));
    });
  });

  group('types1', () {
    test('isList', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data) is List, true);
    });

    test('isListT_pos', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data) is List<int>, true);
    });
  });

  group('types2', () {
    test('isListT_neg', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data) is List<String>, false);
    });

    test('isUint8ClampedList', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data) is Uint8ClampedList, true);
    });

    test('consistent_isUint8ClampedList', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      // Static and dynamic values consistent?  Type inference should be able to
      // constant-fold 'data is Uint8ClampedList' to 'true'.
      expect(inscrutable(data) is Uint8ClampedList == data is Uint8ClampedList,
          isTrue);
    });

    // TODO(sra): Why does this fail on Dartium? There are two types with the
    // same print string:
    //
    //     Expected: ?:<Uint8ClampedList> Actual: ?:<Uint8ClampedList>
    /*
    test('runtimeType', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data).runtimeType, Uint8ClampedList);
    });
    */

    test('consistent_runtimeType', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data).runtimeType == data.runtimeType, isTrue);
    });
  });

  group('types2_runtimeTypeName', () {
    test('runtimeTypeName', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect('${inscrutable(data).runtimeType}', 'Uint8ClampedList');
    });
  });

  group('typed_data', () {
    test('elementSizeInBytes', () {
      var data = context.createImageData(canvas.width, canvas.height).data;
      expect(inscrutable(data).elementSizeInBytes, 1);
    });
  });
}

void checkPixel(List<int> data, int offset, List<int> rgba) {
  offset *= 4;
  for (var i = 0; i < 4; ++i) {
    expect(rgba[i], equals(data[offset + i]));
  }
}
