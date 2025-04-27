// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extra checks that JS types work - Dart functions are not JSFunctions.

import 'dart:js_interop';

import 'package:expect/expect.dart';

@JS()
external JSAny? eval(String code);

@pragma('dart2js:never-inline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

class Class {
  Object method() => this;
  static Class staticMethod() => Class();
}

/// Dart functions are not `JSObject`s.
void testJSObject(void functionArgument()) {
  void localFunction() {
    functionArgument();
  }

  // Top-level function.
  Expect.isFalse(test is JSObject);
  Expect.isFalse(confuse(test) is JSObject);

  // Static function.
  Expect.isFalse(Class.staticMethod is JSObject);
  Expect.isFalse(confuse(Class.staticMethod) is JSObject);

  Expect.isFalse(functionArgument is JSObject);
  Expect.isFalse(confuse(functionArgument) is JSObject);

  Expect.isFalse(localFunction is JSObject);
  Expect.isFalse(confuse(localFunction) is JSObject);

  // Function expression (aka closure)
  Expect.isFalse((() => localFunction) is JSObject);
  Expect.isFalse(confuse(() => localFunction) is JSObject);

  // Instance tear-off
  Expect.isFalse(Class().method is JSObject);
  Expect.isFalse(confuse(Class().method) is JSObject);

  // Top-level function.
  Expect.throws<TypeError>(() => test as JSObject);
  Expect.throws<TypeError>(() => confuse(test) as JSObject);

  // Static function.
  Expect.throws<TypeError>(() => Class.staticMethod as JSObject);
  Expect.throws<TypeError>(() => confuse(Class.staticMethod) as JSObject);

  Expect.throws<TypeError>(() => functionArgument as JSObject);
  Expect.throws<TypeError>(() => confuse(functionArgument) as JSObject);

  Expect.throws<TypeError>(() => localFunction as JSObject);
  Expect.throws<TypeError>(() => confuse(localFunction) as JSObject);

  // Function expression (aka closure)
  Expect.throws<TypeError>(() => (() => localFunction) as JSObject);
  Expect.throws<TypeError>(() => confuse(() => localFunction) as JSObject);

  // Instance tear-off
  Expect.throws<TypeError>(() => Class().method as JSObject);
  Expect.throws<TypeError>(() => confuse(Class().method) as JSObject);
}

/// Dart functions are not `JSFunction`s.
void testJSFunction(void functionArgument()) {
  void localFunction() {
    functionArgument();
  }

  // Top-level function.
  Expect.isFalse(test is JSFunction);
  Expect.isFalse(confuse(test) is JSFunction);

  // Static function.
  Expect.isFalse(Class.staticMethod is JSFunction);
  Expect.isFalse(confuse(Class.staticMethod) is JSFunction);

  Expect.isFalse(functionArgument is JSFunction);
  Expect.isFalse(confuse(functionArgument) is JSFunction);

  Expect.isFalse(localFunction is JSFunction);
  Expect.isFalse(confuse(localFunction) is JSFunction);

  // Function expression (aka closure)
  Expect.isFalse((() => localFunction) is JSFunction);
  Expect.isFalse(confuse(() => localFunction) is JSFunction);

  // Instance tear-off
  Expect.isFalse(Class().method is JSFunction);
  Expect.isFalse(confuse(Class().method) is JSFunction);

  // Top-level function.
  Expect.throws<TypeError>(() => test as JSFunction);
  Expect.throws<TypeError>(() => confuse(test) as JSFunction);

  // Static function.
  Expect.throws<TypeError>(() => Class.staticMethod as JSFunction);
  Expect.throws<TypeError>(() => confuse(Class.staticMethod) as JSFunction);

  Expect.throws<TypeError>(() => functionArgument as JSFunction);
  Expect.throws<TypeError>(() => confuse(functionArgument) as JSFunction);

  Expect.throws<TypeError>(() => localFunction as JSFunction);
  Expect.throws<TypeError>(() => confuse(localFunction) as JSFunction);

  // Function expression (aka closure)
  Expect.throws<TypeError>(() => (() => localFunction) as JSFunction);
  Expect.throws<TypeError>(() => confuse(() => localFunction) as JSFunction);

  // Instance tear-off
  Expect.throws<TypeError>(() => Class().method as JSFunction);
  Expect.throws<TypeError>(() => confuse(Class().method) as JSFunction);
}

void test(void functionArgument()) {
  testJSObject(functionArgument);
  testJSFunction(functionArgument);

  // Some tests that are in the positive.
  final Object? jsFunction = eval('()=>1');

  Expect.isTrue(jsFunction is JSObject);
  Expect.isTrue(jsFunction is JSFunction);

  Expect.isTrue(confuse(jsFunction) is JSObject);
  Expect.isTrue(confuse(jsFunction) is JSFunction);

  confuse(jsFunction) as JSObject;
  confuse(jsFunction) as JSFunction;

  jsFunction as JSObject;
  jsFunction as JSFunction;
}

void main() {
  test(
    ((x) =>
        () => x)(1),
  );
  test(Class().method);
  test(Class.staticMethod);
}
