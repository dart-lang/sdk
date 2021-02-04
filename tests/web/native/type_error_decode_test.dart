// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_error_decode_test;

import 'native_testing.dart';
import 'dart:_js_helper' show NullError, JsNoSuchMethodError;

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
  dynamic x = null;
  dynamic z = Object();
  dynamic v = ([]..length = 1)[0];
  dynamic s = "Cannot call method 'foo' of null";
  dynamic nul = null;
  dynamic f = Foo();

  expectThrows(() => x.fisk(), isNullError);
  expectThrows(() => v.fisk(), isNullError);
  expectThrows(() => z.fisk(), isJsNoSuchMethodError);
  expectThrows(() => s.fisk(), isJsNoSuchMethodError);
  expectThrows(() => (null as dynamic)(), isNullError);
  expectThrows(() => f.field(), isNullError);

  expectThrows(() => confuse(x).fisk(), isNullError);
  expectThrows(() => confuse(v).fisk(), isNullError);
  expectThrows(() => confuse(z).fisk(), isJsNoSuchMethodError);
  expectThrows(() => confuse(s).fisk(), isJsNoSuchMethodError);
  expectThrows(() => confuse(null)(), isNullError);
  expectThrows(() => confuse(f).field(), isNullError);
  expectThrows(() => confuse(f.field)(), isNullError);
}
