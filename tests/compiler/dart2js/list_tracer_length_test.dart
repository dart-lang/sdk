// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST1 = r"""
var a = [42];
main() {
  return a[0];
}
""";

String TEST2(selectorName, args) {
  return """
var a = [42];
main() {
  a.$selectorName($args);
  return a[0];
}
""";
}

const String TEST3 = r"""
var a = new List(42);
main() {
  return a[0];
}
""";

const String TEST4 = r"""
var a = new List(0);
main() {
  return a[0];
}
""";

const String TEST5 = r"""
var a = [42];
main() {
  a.length = 54;
  return a[0];
}
""";

// Test that the order in which we visit the methods will not bring
// back a length after it has been disabled.
const String TEST6 = r"""
foo(b) {
  var a = [42];
  doIt(a);
  return a[0];
}

doIt(a) {
  a.clear();
  foo(a);
}
main() {
  foo(null);
}
""";

void checkRangeError(String test, {bool hasRangeError}) {
  asyncTest(() => compileAll(test).then((generated) {
    Expect.equals(hasRangeError, generated.contains('ioore'));
  }));
}

main() {
  checkRangeError(TEST1, hasRangeError: false);
  checkRangeError(TEST2('insert', 'null, null'), hasRangeError: true);
  checkRangeError(TEST2('add', 'null'), hasRangeError: true);
  checkRangeError(TEST2('clear', ''), hasRangeError: true);
  checkRangeError(TEST2('toString', ''), hasRangeError: false);
  checkRangeError(TEST3, hasRangeError: false);
  checkRangeError(TEST4, hasRangeError: true);
  checkRangeError(TEST5, hasRangeError: true);
  checkRangeError(TEST6, hasRangeError: true);
}
