// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
  class Token {
    final name;
    final value;
    const Token(this.name, [this.value]);
    use() { print(this); }
  }
  test() {
    const [12,53].use();
    const Token('start').use();
    const Token('end').use();
    const Token('yes', 12).use();
    const Token(true, false).use();
  }
""";

main() {
  check(generated, text) {
    Expect.isTrue(generated.contains(text), text);
  }

  asyncTest(() => compile(TEST_ONE, entry: 'test').then((String generated) {
    check(generated, '.List_12_53.');
    check(generated, '.Token_start_null.');
    check(generated, '.Token_end_null.');
    check(generated, '.Token_yes_12.');
    check(generated, '.Token_true_false.');
  }));
}
