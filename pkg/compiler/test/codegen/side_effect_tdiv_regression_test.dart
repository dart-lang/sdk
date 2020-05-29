// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import '../helpers/compiler_helper.dart';

const String TEST = r'''
class A {
  int field = 0;
}
dynamic g;
test(A a) {
  var b = [42, -1];
  var c = a.field;
  g = b[0] ~/ b[1];
  // `~/` on numbers is known to have no effects so it should not block
  // store-forwarding of a field.
  return c + a.field;
}
main() {
  // Assign field so it is not defacto final.
  test(A()..field = 42);
  test(A()..field = 43);
}
''';

void main() {
  runTest() async {
    String generated = await compileAll(TEST);
    Expect.isTrue(generated.contains('return c + c;'),
        "Expected generated code to contain 'return c + c;':\n$generated");
  }

  asyncTest(() async {
    print('--test from kernel----------------------------------------------');
    await runTest();
  });
}
