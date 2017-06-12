// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous2_test;

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
class C {
  external int get x;
  external factory C({int x});
}

@JS()
@anonymous
class B {
  external int get x;
  external factory B({int x});
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

  test('side-casts work for otherwise unreachable types', () {
    var a = new A(x: 3);
    expect(a is B, isTrue);
  });
}
