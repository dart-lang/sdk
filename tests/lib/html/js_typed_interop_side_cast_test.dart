// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library js_typed_interop_anonymous2_test;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@anonymous
class A {
  external int get x;
  external factory A({required int x});
}

@JS()
@anonymous
class C {
  external int get x;
  external factory C({required int x});
}

@JS()
@anonymous
class B {
  external int get x;
  external factory B({required int x});
}

main() {
  test('side-casts work for reachable types', () {
    new C(x: 3); // make C reachable
    dynamic a = new A(x: 3);
    expect(a is C, isTrue);
    C c = a;
    expect(c.x, equals(3));
  });

  test('side-casts work for otherwise unreachable types', () {
    dynamic a = new A(x: 3);
    expect(a is B, isTrue);
  });
}
