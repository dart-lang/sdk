// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:typed_data' show Int32List;
import 'dart:js';

import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

import 'js_test_util.dart';

main() {
  injectJs();

  test('Date', () {
    context['o'] = new DateTime(1995, 12, 17);
    var dateType = context['Date'];
    expect(context.callMethod('isPropertyInstanceOf', ['o', dateType]), isTrue);
    context.deleteProperty('o');
  });

  skipIE9_test('window', () {
    context['o'] = window;
    var windowType = context['Window'];
    expect(
        context.callMethod('isPropertyInstanceOf', ['o', windowType]), isTrue);
    context.deleteProperty('o');
  });

  skipIE9_test('document', () {
    context['o'] = document;
    var documentType = context['Document'];
    expect(context.callMethod('isPropertyInstanceOf', ['o', documentType]),
        isTrue);
    context.deleteProperty('o');
  });

  skipIE9_test('Blob', () {
    var fileParts = ['<a id="a"><b id="b">hey!</b></a>'];
    context['o'] = new Blob(fileParts, 'text/html');
    var blobType = context['Blob'];
    expect(context.callMethod('isPropertyInstanceOf', ['o', blobType]), isTrue);
    context.deleteProperty('o');
  });

  test('unattached DivElement', () {
    context['o'] = new DivElement();
    var divType = context['HTMLDivElement'];
    expect(context.callMethod('isPropertyInstanceOf', ['o', divType]), isTrue);
    context.deleteProperty('o');
  });

  test('Event', () {
    context['o'] = new CustomEvent('test');
    var eventType = context['Event'];
    expect(
        context.callMethod('isPropertyInstanceOf', ['o', eventType]), isTrue);
    context.deleteProperty('o');
  });

  test('KeyRange', () {
    if (IdbFactory.supported) {
      context['o'] = new KeyRange.only(1);
      var keyRangeType = context['IDBKeyRange'];
      expect(context.callMethod('isPropertyInstanceOf', ['o', keyRangeType]),
          isTrue);
      context.deleteProperty('o');
    }
  });

  // this test fails in IE9 for very weird, but unknown, reasons
  // the expression context['ImageData'] fails if useHtmlConfiguration()
  // is called, or if the other tests in this file are enabled
  skipIE9_test('ImageData', () {
    var canvas = new CanvasElement();
    var ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
    context['o'] = ctx.createImageData(1, 1);
    var imageDataType = context['ImageData'];
    expect(context.callMethod('isPropertyInstanceOf', ['o', imageDataType]),
        isTrue);
    context.deleteProperty('o');
  });

  test('typed data: Int32List', () {
    if (Platform.supportsTypedData) {
      context['o'] = new Int32List.fromList([1, 2, 3, 4]);
      var listType = context['Int32Array'];
      // TODO(jacobr): make this test pass. Currently some type information
      // is lost when typed arrays are passed between JS and Dart.
      // expect(context.callMethod('isPropertyInstanceOf', ['o', listType]),
      //    isTrue);
      context.deleteProperty('o');
    }
  });
}
