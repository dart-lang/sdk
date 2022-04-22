// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_util_wasm';
import 'dart:js_wasm';
import 'dart:wasm';

import 'package:expect/expect.dart';

typedef SumStringCallback = String Function(String a, String b);

@JS()
@staticInterop
class DartFromJSCallbackHelper {
  external factory DartFromJSCallbackHelper.factory(SumStringCallback summer);
}

extension DartFromJSCallbackHelperMethods on DartFromJSCallbackHelper {
  external String doSum1();
  external String doSum2(String a, String b);
  external String doSum3(SumStringCallback summer);
}

String sumString(String a, String b) {
  return a + b;
}

void staticInteropCallbackTest() {
  eval(r'''
    globalThis.DartFromJSCallbackHelper = function(summer) {
      this.a = 'hello ';
      this.b = 'world!';
      this.sum = null;
      this.summer = summer;
      this.doSum1 = () => {
        return this.summer(this.a, this.b);
      }
      this.doSum2 = (a, b) => {
        return this.summer(a, b);
      }
      this.doSum3 = (summer) => {
        return summer(this.a, this.b);
      }
    }
  ''');

  final dartFromJSCallbackHelper = DartFromJSCallbackHelper.factory(sumString);
  Expect.equals('hello world!', dartFromJSCallbackHelper.doSum1());
  Expect.equals('foobar', dartFromJSCallbackHelper.doSum2('foo', 'bar'));
  Expect.equals(
      'hello world!', dartFromJSCallbackHelper.doSum3((a, b) => a + b));
}

void allowInteropCallbackTest() {
  eval(r'''
    globalThis.doSum1 = function(summer) {
      return summer('foo', 'bar');
    }
    globalThis.doSum2 = function(a, b) {
      return globalThis.summer(a, b);
    }
  ''');

  final interopCallback = allowInterop<SumStringCallback>((a, b) => a + b);
  Expect.equals('foobar',
      callMethodVarArgs(globalThis(), 'doSum1', [interopCallback]).toString());
  setProperty(globalThis(), 'summer', interopCallback);
  Expect.equals(
      'foobar',
      callMethodVarArgs(globalThis(), 'doSum2', ['foo'.toJS(), 'bar'.toJS()])
          .toString());
  final roundTripCallback = getProperty(globalThis(), 'summer');
  Expect.equals('foobar',
      (dartify(roundTripCallback) as SumStringCallback)('foo', 'bar'));
}

void main() {
  staticInteropCallbackTest();
  allowInteropCallbackTest();
}
