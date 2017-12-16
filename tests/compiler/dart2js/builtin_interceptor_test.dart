// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo() {
  return "foo".length;
}
""";

const String TEST_TWO = r"""
foo() {
  return r"foo".length;
}
""";

const String TEST_THREE = r"""
foo() {
  return new List().add(2);
}
""";

main() {
  test(CompileMode compileMode) async {
    await compile(TEST_ONE, entry: 'foo', compileMode: compileMode,
        check: (String generated) {
      Expect.isTrue(generated.contains("return 3;"));
    });
    await compile(TEST_TWO, entry: 'foo', compileMode: compileMode,
        check: (String generated) {
      Expect.isTrue(generated.contains("return 3;"));
    });
    await compile(TEST_THREE, entry: 'foo', compileMode: compileMode,
        check: (String generated) {
      Expect.isTrue(generated.contains("push(2);"));
    });
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await test(CompileMode.memory);
    print('--test from kernel------------------------------------------------');
    await test(CompileMode.kernel);
  });
}
