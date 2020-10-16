// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests inheritance relationships between `JS` and `anonymous` classes/objects.

@JS()
library extends_test;

import 'package:expect/minitest.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

@JS()
class JSClass {
  external int get a;
  external int getA();
  external int getAOrB();
}

@JS()
@anonymous
class AnonymousClass {
  external int get a;
  external int getA();
}

@JS()
class JSExtendJSClass extends JSClass {
  external JSExtendJSClass(int a, int b);
  external int get b;
  external int getB();
  external int getAOrB();
}

@JS()
class JSExtendAnonymousClass extends AnonymousClass {
  external JSExtendAnonymousClass(int a, int b);
  external int get b;
  external int getB();
}

@JS()
@anonymous
class AnonymousExtendAnonymousClass extends AnonymousClass {
  external int get b;
  external int getB();
}

@JS()
@anonymous
class AnonymousExtendJSClass extends JSClass {
  external int get b;
  external int getB();
  external int getAOrB();
}

external AnonymousExtendAnonymousClass get anonExtendAnon;
external AnonymousExtendJSClass get anonExtendJS;

void testInheritance() {
  // Note that for the following, there are no meaningful tests for is checks or
  // as casts, since the web compilers should return true and succeed for all JS
  // types.

  var jsExtendJS = JSExtendJSClass(1, 2);
  expect(jsExtendJS.a, 1);
  expect(jsExtendJS.b, 2);
  expect(jsExtendJS.getA(), 1);
  expect(jsExtendJS.getB(), 2);
  // Test method overrides.
  expect(jsExtendJS.getAOrB(), 2);
  expect((jsExtendJS as JSClass).getAOrB(), 2);

  var jsExtendAnon = JSExtendAnonymousClass(1, 2);
  expect(jsExtendAnon.a, 1);
  expect(jsExtendAnon.b, 2);
  expect(jsExtendAnon.getA(), 1);
  expect(jsExtendAnon.getB(), 2);

  expect(anonExtendAnon.a, 1);
  expect(anonExtendAnon.b, 2);
  expect(anonExtendAnon.getA(), 1);
  expect(anonExtendAnon.getB(), 2);

  expect(anonExtendJS.a, 1);
  expect(anonExtendJS.b, 2);
  expect(anonExtendJS.getA(), 1);
  expect(anonExtendJS.getB(), 2);
  expect(anonExtendJS.getAOrB(), 2);
  expect((anonExtendJS as JSClass).getAOrB(), 2);
}
