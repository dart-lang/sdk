// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--experimental-trust-js-interop-type-annotations

// Similar test to js_typed_interop_side_cast, but because we are using the
// --experimental-trust-js-interop-type-annotations flag, we test a slighly
// different behavior.
@JS()
library js_typed_interop_side_cast_exp_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@JS()
@anonymous
class A {
  external int get x;
  external factory A({int x});
}

@JS()
@anonymous
class B {
  external int get x;
  external factory B({int x});
}

@JS()
@anonymous
class C {
  external int get x;
  external factory C({int x});
}

main() {
  useHtmlConfiguration();

  test('side-casts work for reachable types', () {
    new C(x: 3); // make C reachable
    var a = new A(x: 3);
    expect(a is C, isTrue);
    C c = a;
    expect(c.x, equals(3));
  });

  // Note: this test would fail without the experimental flag.
  test('side-casts do not work for unreachable types', () {
    var a = new A(x: 3);
    expect(a is B, isFalse);
  });
}
