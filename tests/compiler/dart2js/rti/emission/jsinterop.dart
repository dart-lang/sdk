// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

@JS()
library jsinterop;

/*class: global#JavaScriptObject:checks=[$isA,$isC],instance*/

import 'package:js/js.dart';

/*class: A:checkedInstance,checks=[],instance*/
@JS()
class A {
  external A();
}

/*class: B:checks=[],instance*/
@JS('BClass')
class B {
  external B();
}

/*class: C:checkedInstance,checks=[],instance*/
@JS()
@anonymous
class C {
  external factory C();
}

/*class: D:checks=[],instance*/
@JS()
@anonymous
class D {
  external factory D();
}

/*class: E:checks=[],instance,typeLiteral*/
class E {
  E();
}

/*class: F:checks=[],instance*/
class F {
  F();
}

@pragma('dart2js:noInline')
test(o) => o is A || o is C || o is E;

main() {
  test(new A());
  test(new B());
  test(new C());
  test(new D());
  test(new E());
  test(new F());
}
