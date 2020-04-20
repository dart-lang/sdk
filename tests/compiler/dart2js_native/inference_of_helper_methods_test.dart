// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'native_testing.dart';
import 'dart:_js_helper' show intTypeCheck;

bool get inComplianceMode {
  try {
    String a = (42 as dynamic);
  } on TypeError catch (e) {
    return true;
  }
  return false;
}

main() {
  var a = [];
  a.add(42);
  a.add('foo');
  // By calling directly [intTypeCheck] with an int, we're making the
  // type inferrer infer that the parameter type of [intTypeCheck] is
  // always an int, and therefore the method will be compiled to
  // never throw. So when the backend actually uses the helper for
  // implementing checked mode semantics (like in the check below),
  // the check won't fail at runtime.
  intTypeCheck(42);
  if (inComplianceMode) {
    int value;
    Expect.throws(() => value = a[1], (e) => e is TypeError);
  }
}
