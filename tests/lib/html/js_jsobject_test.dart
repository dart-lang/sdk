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

  test('new Foo()', () {
    var foo = new JsObject(context['Foo'], [42]);
    expect(foo['a'], equals(42));
    expect(foo.callMethod('bar'), equals(42));
    expect(() => foo.callMethod('baz'), throwsNoSuchMethodError);
  });

  test('new container.Foo()', () {
    final Foo2 = context['container']['Foo'];
    final foo = new JsObject(Foo2, [42]);
    expect(foo['a'], 42);
    expect(Foo2['b'], 38);
  });

  test('new Array()', () {
    var a = new JsObject(context['Array']);
    expect(a is JsArray, isTrue);

    // Test that the object still behaves via the base JsObject interface.
    // JsArray specific tests are below.
    expect(a['length'], 0);

    a.callMethod('push', ["value 1"]);
    expect(a['length'], 1);
    expect(a[0], "value 1");

    a.callMethod('pop');
    expect(a['length'], 0);
  });

  test('new Date()', () {
    final a = new JsObject(context['Date']);
    expect(a.callMethod('getTime'), isNotNull);
  });

  test('new Date(12345678)', () {
    final a = new JsObject(context['Date'], [12345678]);
    expect(a.callMethod('getTime'), equals(12345678));
  });

  test('new Date("December 17, 1995 03:24:00 GMT")', () {
    final a = new JsObject(context['Date'], ["December 17, 1995 03:24:00 GMT"]);
    expect(a.callMethod('getTime'), equals(819170640000));
  });

  test('new Date(1995,11,17)', () {
    // Note: JS Date counts months from 0 while Dart counts from 1.
    final a = new JsObject(context['Date'], [1995, 11, 17]);
    final b = new DateTime(1995, 12, 17);
    expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
  });

  test('new Date(1995,11,17,3,24,0)', () {
    // Note: JS Date counts months from 0 while Dart counts from 1.
    final a = new JsObject(context['Date'], [1995, 11, 17, 3, 24, 0]);
    final b = new DateTime(1995, 12, 17, 3, 24, 0);
    expect(a.callMethod('getTime'), equals(b.millisecondsSinceEpoch));
  });

  test('new Object()', () {
    final a = new JsObject(context['Object']);
    expect(a, isNotNull);

    a['attr'] = "value";
    expect(a['attr'], equals("value"));
  });

  test(r'new RegExp("^\w+$")', () {
    final a = new JsObject(context['RegExp'], [r'^\w+$']);
    expect(a, isNotNull);
    expect(a.callMethod('test', ['true']), isTrue);
    expect(a.callMethod('test', [' false']), isFalse);
  });

  test('js instantiation via map notation : new Array()', () {
    final a = new JsObject(context['Array']);
    expect(a, isNotNull);
    expect(a['length'], equals(0));

    a.callMethod('push', ["value 1"]);
    expect(a['length'], equals(1));
    expect(a[0], equals("value 1"));

    a.callMethod('pop');
    expect(a['length'], equals(0));
  });

  test('js instantiation via map notation : new Date()', () {
    final a = new JsObject(context['Date']);
    expect(a.callMethod('getTime'), isNotNull);
  });

  test('typed array', () {
    if (Platform.supportsTypedData) {
      // Safari's ArrayBuffer is not a Function and so doesn't support bind
      // which JsObject's constructor relies on.
      // bug: https://bugs.webkit.org/show_bug.cgi?id=122976
      if (context['ArrayBuffer']['bind'] != null) {
        final codeUnits = "test".codeUnits;
        final buf = new JsObject(context['ArrayBuffer'], [codeUnits.length]);
        final bufView = new JsObject(context['Uint8Array'], [buf]);
        for (var i = 0; i < codeUnits.length; i++) {
          bufView[i] = codeUnits[i];
        }
      }
    }
  });

  test('>10 parameters', () {
    final o = new JsObject(context['Baz'], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    for (var i = 1; i <= 11; i++) {
      expect(o["f$i"], i);
    }
    expect(o['constructor'], equals(context['Baz']));
  });
}
