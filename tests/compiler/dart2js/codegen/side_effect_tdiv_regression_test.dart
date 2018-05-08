// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import '../compiler_helper.dart';

const String TEST = r'''
class A {
  var field = 42;
}
main() {
  var a = new A();
  var b = [42, -1];
  // Force a setter on [field].
  if (false) a.field = 12;
  var c = a.field;
  print(b[0] ~/ b[1]);
  return c + a.field;
}
''';

void main() {
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST, useKernel: useKernel);
    Expect.isTrue(generated.contains('return c + c;'),
        "Expected generated code to contain 'return c + c;':\n$generated");
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel----------------------------------------------');
    await runTest(useKernel: true);
  });
}
