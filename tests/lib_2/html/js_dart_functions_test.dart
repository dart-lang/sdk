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

  test('invoke Dart callback from JS', () {
    expect(() => context.callMethod('invokeCallback'), throws);

    context['callback'] = () => 42;
    expect(context.callMethod('invokeCallback'), equals(42));

    context.deleteProperty('callback');
  });

  test('pass a Dart function to JS and back', () {
    var dartFunction = () => 42;
    context['dartFunction'] = dartFunction;
    expect(identical(context['dartFunction'], dartFunction), isTrue);
    context.deleteProperty('dartFunction');
  });

  test('callback as parameter', () {
    expect(context.callMethod('getTypeOf', [context['razzle']]),
        equals("function"));
  });

  test('invoke Dart callback from JS with this', () {
    // A JavaScript constructor function implemented in Dart which
    // uses 'this'
    final constructor = new JsFunction.withThis(($this, arg1) {
      var t = $this;
      $this['a'] = 42;
    });
    var o = new JsObject(constructor, ["b"]);
    expect(o['a'], equals(42));
  });

  test('invoke Dart callback from JS with 11 parameters', () {
    context['callbackWith11params'] =
        (p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) =>
            '$p1$p2$p3$p4$p5$p6$p7$p8$p9$p10$p11';
    expect(context.callMethod('invokeCallbackWith11params'),
        equals('1234567891011'));
  });

  test('return a JS proxy to JavaScript', () {
    var result = context.callMethod('testJsMap', [
      () => new JsObject.jsify({'value': 42})
    ]);
    expect(result, 42);
  });

  test('emulated functions should be callable in JS', () {
    context['callable'] = new Callable();
    var result = context.callMethod('callable');
    expect(result, 'called');
    context.deleteProperty('callable');
  });
}
