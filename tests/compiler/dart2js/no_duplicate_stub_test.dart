// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String TEST = r"""
class A {
  foo({a, b}) {}
}

class B extends A {
}

main() {
  var a = [bar, baz];
  a[0](new A());
  a[1](new A());
}

bar(a) {
  if (a is A) a.foo(a: 42);
}

baz(a) {
  if (a is B) a.foo(a: 42);
}
""";

main() {
  runTest({bool useKernel}) async {
    String generated = await compileAll(TEST,
        compileMode: useKernel ? CompileMode.kernel : CompileMode.memory);
    RegExp regexp = new RegExp('foo\\\$1\\\$a: function');
    Iterator<Match> matches = regexp.allMatches(generated).iterator;
    checkNumberOfMatches(matches, 1);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
