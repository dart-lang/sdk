// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises a sound null safety issue that arose in the compiler by
// allocating an argument slot for a type parameter that was determined to be
// unused. This resulted in `null` being added to a list that wouldn't otherwise
// need to support null.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST = r"""
class A {
  Object? value;
  @pragma('dart2js:tryInline')
  @pragma('dart2js:as:trust')
  T foo<T>() => value as T;
}

void main () {
  final a = A();
  a.value = 'val';
  a.foo();
}
""";

main() {
  test() async {
    await compile(TEST, enableTypeAssertions: true, disableInlining: false,
        check: (generated) {
      // 'foo' should be inlined and no type arg should be needed.
      Expect.isFalse(generated.contains('foo'));
    });
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await test();
  });
}
