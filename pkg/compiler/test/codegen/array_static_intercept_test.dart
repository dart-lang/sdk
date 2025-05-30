// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST_ONE = r"""
foo(List<int> a) {
  a.add(42);
  a.removeLast();
  return a.length;
}
""";

main() {
  asyncTest(() async {
    await compile(
      TEST_ONE,
      entry: 'foo',
      check: (String generated) {
        Expect.isTrue(generated.contains(r'.add$1('));
        Expect.isTrue(generated.contains(r'.removeLast$0('));
        Expect.isTrue(
          generated.contains(r'.length'),
          "Unexpected code to contain '.length':\n$generated",
        );
      },
    );
  });
}
