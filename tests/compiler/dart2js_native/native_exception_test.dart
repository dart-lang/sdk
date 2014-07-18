// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js can handle unexpected exception types.

library native_exception_test;

import 'dart:_foreign_helper' show JS;
import 'dart:_js_helper';
import 'package:expect/expect.dart';

main() {
  var previous;
  check(e) {
    print('$e');
    Expect.equals(e, e);
    Expect.notEquals(e, new Object());
    Expect.notEquals(e, previous);
    previous = e;
    return '$e' != '[object Object]';
  }
  Expect.throws(() { JS('void', 'noGlobalVariableWithThisName'); }, check);
  Expect.throws(() { JS('void', 'throw 3'); }, check);
  Expect.throws(
      () {
        JS('bool', 'Object.prototype.hasOwnProperty.call(undefined, "foo")');
      },
      check);
  Expect.throws(() { JS('void', 'throw new ReferenceError()'); }, check);
  Expect.throws(() { JS('void', 'throw void 0'); }, check);
  Expect.throws(() { JS('void', 'throw "a string"'); }, check);
  Expect.throws(() { JS('void', 'throw null'); }, check);
}
