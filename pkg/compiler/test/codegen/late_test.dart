// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST = r"""
class Foo {
  late int x;
}

int foo() {
  final foo = Foo();
  foo.x = 40;
  return foo.x + 2;
  // present: '+ 2'
  // absent: 'add'
}
""";

Future check(String test) {
  return compile(test,
      entry: 'foo',
      check: checkerForAbsentPresent(test),
      disableTypeInference: false,
      disableInlining: false,
      soundNullSafety: true);
}

void main() {
  asyncTest(() async {
    await check(TEST);
  });
}
