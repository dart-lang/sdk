// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:async_helper/async_helper.dart";
import '../helpers/compiler_helper.dart';

const String CODE = """
class A {
  A(String b) { b.length; }
}

main() {
  new A("foo");
}
""";

main() {
  runTest() async {
    String generated = await compileAll(CODE);

    RegExp regexp = RegExp(r'\.A\.prototype = {');
    Iterator<Match> matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 1);

    RegExp regexp2 = RegExp(r'A\$\w+: function');
    Iterator<Match> matches2 = regexp2.allMatches(generated).iterator;
    checkNumberOfMatches(matches2, 1);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
