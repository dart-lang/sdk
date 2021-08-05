// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Tests the functionality of object properties with the js_util library that
// involve implicit type checks.

@JS()
library js_util_properties_implicit_checks_test;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
class CallMethodTest {
  external CallMethodTest();

  external one(a);
}

main() {
  eval(r"""
    function CallMethodTest() {}

    CallMethodTest.prototype.one = function(a) {
      return 'one';
    }
    """);

  var o = CallMethodTest();
  expect(() => js_util.callMethod(o, 'one', <String>[5 as dynamic]), throws);
  expect(() => js_util.callMethod(o, 'one', <int>['foo' as dynamic]), throws);
}
