// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--experimental-trust-js-interop-type-annotations

// Same test as js_typed_interop_anonymous2, but using the
// --experimental-trust-js-interop-type-annotations flag.
@JS()
library js_typed_interop_anonymous2_exp_test;

import 'dart:html';
import 'dart:js' as js;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
@anonymous
class A {
  external factory A({B? b});

  external B? get b;
}

@JS()
@anonymous
class B {
  external factory B({C? c});

  external C? get c;
}

@JS()
@anonymous
class C {
  external factory C();
}

// D is unreachable, and that is OK
@JS()
@anonymous
class D {
  external factory D();
}

main() {
  test('simple', () {
    var b = new B();
    var a = new A(b: b);
    expect(a.b, equals(b));
    expect(b.c, isNull);
  });
}
