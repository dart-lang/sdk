// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

// Negative constant numbers must be generated as negation, not just a literal
// with a sign, i.e.
//
//     (-5).toString()
//
// not
//
//     -5 .toString()
//
// The unparethesized version is `-(5 .toString())`, which creates the string
// `"5"`, then converts it to a number for negation, giving a number result
// instead of a string result.

@pragma('dart2js:noInline')
checkString(r) {
  Expect.isTrue(
      r is String, 'Expected string, found ${r} of type ${r.runtimeType}');
}

test1() {
  checkString(JS('', '#.toString()', -5));
}

test2() {
  checkString(JS('', '#.toString()', -1.5));
}

test3() {
  checkString(JS('', '#.toString()', -0.0));
}

main() {
  test1();
  test2();
  test3();
}
