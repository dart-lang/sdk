// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../helpers/compiler_helper.dart';
import "package:expect/async_helper.dart";

const String CODE = """
var x = 0;
class A {
  A() { x++; }
}

class B extends A {
  B();
}

main() {
  B();
  A();
}
""";

main() {
  runTest() async {
    String generated = await compileAll(CODE);
    RegExp regexp = RegExp(r'A\$0\(\) {');
    Iterator<Match> matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 1);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
