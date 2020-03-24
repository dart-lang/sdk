// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
  class Token {
    @pragma('dart2js:noElision')
    final name;
    @pragma('dart2js:noElision')
    final value;
    const Token(this.name, [this.value]);
    use() { print(this); }
  }
  test() {
    (const [12,53] as dynamic).use();
    const Token('start').use();
    const Token('end').use();
    const Token('yes', 12).use();
    const Token(true, false).use();
  }
""";

main() {
  check(String generated, String text) {
    Expect.isTrue(generated.contains(text), text);
  }

  runTests() async {
    String generated = await compile(TEST_ONE, entry: 'test');
    check(generated, '.List_12_53.');
    check(generated, '.Token_start_null.');
    check(generated, '.Token_end_null.');
    check(generated, '.Token_yes_12.');
    check(generated, '.Token_true_false.');
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
