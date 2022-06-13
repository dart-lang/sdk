// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST_DIRECT = r"""
class Foo {
  late int x;
}

int test() {
  final foo = Foo();
  foo.x = 40;
  return foo.x + 2;
  // present: '42'
  // absent: '+ 2'
  // absent: 'add'
}
""";

const String TEST_INDIRECT = r"""
class Foo {
  late int x;
}

int entry() {
  final foo = Foo();
  foo.x = 40;
  return test(foo);
}

@pragma('dart2js:noInline')
int test(Foo foo) {
  return foo.x + 2;
  // present: '+ 2'
  // absent: 'add'
}
""";

Future check(String test, {String entry: 'test'}) {
  return compile(test,
      entry: entry,
      methodName: 'test',
      check: checkerForAbsentPresent(test),
      disableTypeInference: false,
      disableInlining: false,
      soundNullSafety: true);
}

void main() {
  asyncTest(() async {
    await check(TEST_DIRECT);
    await check(TEST_INDIRECT, entry: 'entry');
  });
}
