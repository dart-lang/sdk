// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo(a) {
  a.add(42);
  a.removeLast();
  return a.length;
}
""";

main() {
  test(CompileMode compileMode) async {
    await compile(TEST_ONE, entry: 'foo', compileMode: compileMode,
        check: (String generated) {
      Expect.isTrue(generated.contains(r'.add$1('));
      Expect.isTrue(generated.contains(r'.removeLast$0('));
      Expect.isTrue(generated.contains(r'.length'),
          "Unexpected code to contain '.length':\n$generated");
    });
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await test(CompileMode.memory);
    print('--test from kernel------------------------------------------------');
    await test(CompileMode.kernel);
  });
}
