// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
@anonymous
class Literal {
  external factory Literal({int x, String y, num z, Function foo});

  external int get x;
  external String get y;
  external num get z;
  external Function get foo;
}

@JS()
@anonymous
class FunctionWithExpando {
  external int call();
  external String get myExpando;
}

main() {
  test('object', () {
    dynamic l = new Literal(x: 3, y: 'foo', foo: allowInterop((x) => x * 2));
    expect(l.x, equals(3));
    expect(l.y, equals('foo'));
    expect(l.z, isNull);
    expect(l.foo(4), equals(8));
  });

  test('function', () {
    // Get a JS function.
    dynamic f = js_util.getProperty(window, 'addEventListener');
    js_util.setProperty(f, 'myExpando', 'foo');
    expect(f.myExpando, equals('foo'));
  });

  test('dart object', () {
    dynamic o = new Object();
    js_util.setProperty(o, 'x', 3);
    expect(() => o.x, throwsNoSuchMethodError);
    expect(() => o.foo(), throwsNoSuchMethodError);
  });
}
