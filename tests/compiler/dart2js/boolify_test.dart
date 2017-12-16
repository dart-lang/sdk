// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library boolify_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST = r"""
foo() {
  var a = foo();
  if (!a) return 1;
  return 2;
}
""";

main() {
  test(CompileMode compileMode) async {
    await compile(TEST, entry: 'foo', compileMode: compileMode,
        check: (String generated) {
      Expect.isTrue(generated.contains('foo() !== true)'));
    });
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await test(CompileMode.memory);
    print('--test from kernel------------------------------------------------');
    await test(CompileMode.kernel);
  });
}
