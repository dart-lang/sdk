// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_error_decode_test;

import 'package:expect/expect.dart';

import 'dart:_js_helper';

class Foo {
  var field;
}

isNullError(e, trace) {
  print('$e\nTrace: $trace');
  return e is NullError;
}

isJsNoSuchMethodError(e, trace) {
  print('$e\nTrace: $trace');
  return e is JsNoSuchMethodError;
}

expectThrows(f, check) {
  try {
    f();
  } catch (e, trace) {
    if (check(e, trace)) {
      return;
    }
    throw 'Unexpected exception: $e\n$trace';
  }
  throw 'No exception thrown';
}

main() {
  var x = null;
  var z = new Object();
  var v = new List(1)[0];
  var s = "Cannot call method 'foo' of null";
  var nul = null;
  var f = new Foo();
  // This should foil code analysis so the variables aren't inlined below.
  [].forEach((y) => f.field = nul = s = x = z = v = y);
  expectThrows(() => x.fisk(), isNullError);
  expectThrows(() => v.fisk(), isNullError);
  expectThrows(() => z.fisk(), isJsNoSuchMethodError);
  expectThrows(() => s.fisk(), isJsNoSuchMethodError);
  expectThrows(() => null(), isNullError);
  expectThrows(() => f.field(), isNullError);
}
