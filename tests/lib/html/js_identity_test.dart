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

  test('context instances should be identical', () {
    var c1 = context;
    var c2 = context;
    expect(identical(c1, c2), isTrue);
  });

  test('identical JS objects should have identical proxies', () {
    var o1 = new JsObject(context['Foo'], [1]);
    context['f1'] = o1;
    var o2 = context['f1'];
    expect(identical(o1, o2), isTrue);
  });

  test('identical Dart functions should have identical proxies', () {
    var f1 = allowInterop(() => print("I'm a Function!"));
    expect(context.callMethod('identical', [f1, f1]), isTrue);
  });

  test('identical JS functions should have identical proxies', () {
    var f1 = context['Object'];
    var f2 = context['Object'];
    expect(identical(f1, f2), isTrue);
  });

  // TODO(justinfagnani): old tests duplicate checks above, remove
  // on test next cleanup pass
  test('test proxy equality', () {
    var foo1 = new JsObject(context['Foo'], [1]);
    var foo2 = new JsObject(context['Foo'], [2]);
    context['foo1'] = foo1;
    context['foo2'] = foo2;
    expect(foo1, notEquals(context['foo2']));
    expect(foo2, equals(context['foo2']));
    context.deleteProperty('foo1');
    context.deleteProperty('foo2');
  });

  test('retrieve same dart Object', () {
    final obj = new Object();
    context['obj'] = obj;
    expect(context['obj'], same(obj));
    context.deleteProperty('obj');
  });
}
