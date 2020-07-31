// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// TODO(johnniwinther): Currently this only works with the mock compiler.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

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

const String TEST7 = r"""
var a = [42, 54];
main() {
  a[0]++;
  return a[1];
}
""";

const String TEST8 = r"""
var b = int.parse('42');
var a = new List(b);
main() {
  return a[1];
}
""";

const String TEST9 = r"""
const b = 42;
var a = new List(b);
main() {
  return a[1];
}
""";

checkRangeError(String test, {bool hasRangeError, String methodName}) async {
  String generated =
      await compile(test, methodName: methodName, disableTypeInference: false);
  Expect.equals(
      hasRangeError,
      generated.contains('ioore'),
      "Unexpected use of 'hasRangeError' for test:\n$test\n"
      "in code\n$generated");
}

main() {
  asyncTest(() async {
    await checkRangeError(TEST1, hasRangeError: false);
    await checkRangeError(TEST2('insert', 'null, null'), hasRangeError: true);
    await checkRangeError(TEST2('add', 'null'), hasRangeError: true);
    await checkRangeError(TEST2('clear', ''), hasRangeError: true);
    await checkRangeError(TEST2('toString', ''), hasRangeError: false);
    await checkRangeError(TEST3, hasRangeError: false);
    await checkRangeError(TEST4, hasRangeError: true);
    await checkRangeError(TEST5, hasRangeError: true);
    await checkRangeError(TEST6, hasRangeError: true, methodName: 'foo');
    await checkRangeError(TEST7, hasRangeError: false);
    await checkRangeError(TEST8, hasRangeError: true);
    await checkRangeError(TEST9, hasRangeError: false);
  });
}
