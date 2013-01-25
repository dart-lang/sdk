// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST_ONE = r"""
  foo(a) {
    // Make sure there is a bailout version.
    foo(a);
    // This will make a one shot interceptor that will be optimized in
    // the non-bailout version because we know a is a number.
    return (a + 42).toString;
  }
""";

main() {
  var generated = compile(TEST_ONE, entry: 'foo');
  // Check that the one shot interceptor got converted to a direct
  // call to the interceptor object.
  Expect.isTrue(generated.contains('CONSTANT.get\$toString(a + 42);'));
}
