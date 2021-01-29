// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--enable-asserts

// Tests that `js_util` methods correctly check that function arguments allow
// interop.

@JS()
library assert_function_interop_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
class JSClass {
  external JSClass();
}

@JS()
external get JSClassWithFuncArgs;

@JS()
external void Function() get jsFunction;

void dartFunction() {}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
confuse(x) => x;

void main() {
  eval(r"""
    function JSClass() {
      this.functionProperty = function() {};
      this.methodWithFuncArgs = function(f1, f2) {
        f1();
        if (arguments.length == 2) f2();
      };
    }
    function JSClassWithFuncArgs(f1, f2) {
      f1();
      if (arguments.length == 2) f2();
    }
    function jsFunction() {}
  """);

  var jsClass = JSClass();
  dynamic d = confuse(dartFunction);
  var interopFunction = allowInterop(dartFunction);
  var interopDynamic = confuse(allowInterop(dartFunction));

  // Functions that aren't wrapped with `allowInterop` should throw.
  Expect.throws(
      () => js_util.setProperty(jsClass, 'functionProperty', dartFunction));
  Expect.throws(() => js_util.setProperty(jsClass, 'functionProperty', d));
  // Correctly wrapped functions should not throw.
  js_util.setProperty(jsClass, 'functionProperty', interopFunction);
  js_util.setProperty(jsClass, 'functionProperty', interopDynamic);

  // Using a JS function should not throw.
  js_util.setProperty(jsClass, 'functionProperty', jsFunction);

  Expect.throws(
      () => js_util.callMethod(jsClass, 'methodWithFuncArgs', [dartFunction]));
  Expect.throws(() => js_util.callMethod(jsClass, 'methodWithFuncArgs', [d]));
  js_util.callMethod(jsClass, 'methodWithFuncArgs', [interopFunction]);
  js_util.callMethod(jsClass, 'methodWithFuncArgs', [interopDynamic]);
  // Check to see that all arguments are checked.
  Expect.throws(() => js_util.callMethod(
      jsClass, 'methodWithFuncArgs', [interopFunction, dartFunction]));
  js_util.callMethod(
      jsClass, 'methodWithFuncArgs', [interopFunction, interopFunction]);

  js_util.callMethod(jsClass, 'methodWithFuncArgs', [jsFunction]);

  Expect.throws(
      () => js_util.callConstructor(JSClassWithFuncArgs, [dartFunction]));
  Expect.throws(() => js_util.callConstructor(JSClassWithFuncArgs, [d]));
  js_util.callConstructor(JSClassWithFuncArgs, [interopFunction]);
  js_util.callConstructor(JSClassWithFuncArgs, [interopDynamic]);
  Expect.throws(() => js_util
      .callConstructor(JSClassWithFuncArgs, [interopFunction, dartFunction]));
  js_util
      .callConstructor(JSClassWithFuncArgs, [interopFunction, interopFunction]);

  js_util.callConstructor(JSClassWithFuncArgs, [jsFunction]);
}
