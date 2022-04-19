// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/compiler_helper.dart';

const String TEST = r"""
class Foo {
  late int x;
}

void entry() {
  final foo = Foo();
  foo.x = 42;
  test(foo);
}

@pragma('dart2js:noInline')
void test(Foo foo) {
  final a = foo.x;
  final b = foo.x;
  print([a, b]);
}
""";

void main() {
  asyncTest(() async {
    await compile(TEST,
        entry: 'entry',
        methodName: 'test',
        disableTypeInference: false,
        disableInlining: false,
        soundNullSafety: true, check: (String generated) {
      RegExp regexp = new RegExp(r'=== \$');
      Expect.equals(1, regexp.allMatches(generated).length);
    });
  });
}
