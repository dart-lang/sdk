// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Currently this only works with the mock compiler.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import '../compiler_helper.dart';

const String TEST1 = r"""
main() {
  var a = [42, null];
  return a[0] + 42;
}
""";

const String TEST2 = r"""
main() {
  var a = new List();
  a.add(42);
  a.add(null);
  return a[0] + 42;
}
""";

const String TEST3 = r"""
main() {
  var a = new List(42);
  a[a.length - 1] = 42;
  return a[0] + 42;
}
""";

const String TEST4 = r"""
main() {
  var a = new List.filled(42, null);
  a[a.length - 1] = 42;
  return 42 + a[0];
}
""";

// Test that the backend knows the element type of a const list.
const String TEST5 = r"""
var b = 4;
main() {
  var a = const [1, 2, 3];
  return 42 + a[b];
}
""";

// Test that the backend knows the element type of a const static.
const String TEST6 = r"""
const a = const [1, 2, 3];
var b = 4;
main() {
  return 42 + a[b];
}
""";

String generateTest(String call) {
  return """
main() {
  List differentType = [true, false];
  List a = [42];
  return a.$call + 42;
}
""";
}

main() {
  runTests({bool useKernel}) async {
    bool useKernel = false;
    String generated1 = await compileAll(TEST1, useKernel: useKernel);
    Expect.isTrue(generated1.contains('if (typeof t1'));

    String generated2 = await compileAll(TEST2, useKernel: useKernel);
    Expect.isTrue(generated2.contains('if (typeof t1'));

    String generated3 = await compileAll(TEST3, useKernel: useKernel);
    Expect.isTrue(generated3.contains('if (typeof t1'));

    String generated4 = await compileAll(TEST4, useKernel: useKernel);
    Expect.isTrue(generated4.contains('if (typeof t1'));

    String generated5 = await compileAll(TEST5, useKernel: useKernel);
    Expect.isFalse(generated5.contains('iae'));

    String generated6 = await compileAll(TEST6, useKernel: useKernel);
    Expect.isFalse(generated6.contains('iae'));

    var memberInvocations = const <String>[
      'first',
      'last',
      'single',
      'singleWhere((x) => true)',
      'elementAt(0)',
      'removeAt(0)',
      'removeLast()',
    ];
    for (String member in memberInvocations) {
      String generated = await compileAll(generateTest('$member'),
          expectedErrors: 0, expectedWarnings: 0, useKernel: useKernel);
      Expect.isTrue(
          generated.contains('+ 42'),
          "Missing '+ 42' code for invocation '$member':\n"
          "$generated");
      // TODO(johnniwinther): Update this test to query the generated code for
      // main only.
      /*Expect.isFalse(
          generated.contains('if (typeof t1'),
          "Unexpected 'if (typeof t1' code for invocation '$member':\n"
          "$generated");
      Expect.isFalse(
          generated.contains('if (t1 == null)'),
          "Unexpected 'if (t1 == null)' code for invocation '$member':\n"
          "$generated");*/
    }
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
  });
}
