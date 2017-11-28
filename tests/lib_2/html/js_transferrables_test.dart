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

  test('DateTime', () {
    var date = context.callMethod('getNewDate');
    expect(date is DateTime, isTrue);
  });

  test('window', () {
    expect(context['window'] is Window, isTrue);
  });

  test('foreign browser objects should be proxied', () {
    var iframe = new IFrameElement();
    document.body.children.add(iframe);
    var proxy = new JsObject.fromBrowserObject(iframe);

    // Window
    var contentWindow = proxy['contentWindow'];
    expect(contentWindow is! Window, isTrue);
    expect(contentWindow is JsObject, isTrue);

    // Node
    var foreignDoc = contentWindow['document'];
    expect(foreignDoc is! Node, isTrue);
    expect(foreignDoc is JsObject, isTrue);

    // Event
    var clicked = false;
    foreignDoc['onclick'] = (e) {
      expect(e is! Event, isTrue);
      expect(e is JsObject, isTrue);
      clicked = true;
    };

    context.callMethod('fireClickEvent', [contentWindow]);
    expect(clicked, isTrue);
  });

  test('foreign functions pass function is checks', () {
    var iframe = new IFrameElement();
    document.body.children.add(iframe);
    var proxy = new JsObject.fromBrowserObject(iframe);

    var contentWindow = proxy['contentWindow'];
    var foreignDoc = contentWindow['document'];

    // Function
    var foreignFunction = foreignDoc['createElement'];
    expect(foreignFunction is JsFunction, isTrue);

    // Verify that internal isChecks in callMethod work.
    foreignDoc.callMethod('createElement', ['div']);

    var typedContentWindow = js_util.getProperty(iframe, 'contentWindow');
    var typedForeignDoc = js_util.getProperty(typedContentWindow, 'document');

    var typedForeignFunction =
        js_util.getProperty(typedForeignDoc, 'createElement');
    expect(typedForeignFunction is Function, isTrue);
    js_util.callMethod(typedForeignDoc, 'createElement', ['div']);
  });

  test('document', () {
    expect(context['document'] is Document, isTrue);
  });

  skipIE9_test('Blob', () {
    var blob = context.callMethod('getNewBlob');
    expect(blob is Blob, isTrue);
    expect(blob.type, equals('text/html'));
  });

  test('unattached DivElement', () {
    var node = context.callMethod('getNewDivElement');
    expect(node is DivElement, isTrue);
  });

  test('Event', () {
    var event = context.callMethod('getNewEvent');
    expect(event is Event, true);
  });

  test('KeyRange', () {
    if (IdbFactory.supported) {
      var node = context.callMethod('getNewIDBKeyRange');
      expect(node is KeyRange, isTrue);
    }
  });

  test('ImageData', () {
    var node = context.callMethod('getNewImageData');
    expect(node is ImageData, isTrue);
  });

  test('typed data: Int32Array', () {
    if (Platform.supportsTypedData) {
      var list = context.callMethod('getNewInt32Array');
      print(list);
      expect(list is Int32List, isTrue);
      expect(list, equals([1, 2, 3, 4, 5, 6, 7, 8]));
    }
  });
}
