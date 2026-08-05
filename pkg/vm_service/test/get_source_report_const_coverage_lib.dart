// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';
import 'get_source_report_const_coverage_helper.dart' as lib;

class Foo {
  final int x;
  // Expect this constructor to be coverage by coverage.
  const Foo([int? x]) : x = x ?? 42; // LINE_A
  // Expect this constructor to be coverage by coverage too.
  const Foo.named1([int? x]) : x = x ?? 42; // LINE_B
  // Expect this constructor to *NOT* be coverage by coverage.
  const Foo.named2([int? x]) : x = x ?? 42; // LINE_C
  // Expect this constructor to be coverage by coverage too (from lib).
  const Foo.named3([int? x]) : x = x ?? 42; // LINE_D
}

void testFunction() {
  const foo = Foo();
  const foo2 = Foo();
  const fooIdentical = identical(foo, foo2);
  print(fooIdentical);

  const namedFoo = Foo.named1();
  const namedFoo2 = Foo.named1();
  // ignore: unused_local_variable
  const namedIdentical = identical(namedFoo, namedFoo2);
  print(fooIdentical);

  debugger(); // LINE_E

  // That this is called after (or at all) is not relevent for the code
  // coverage of constants.
  lib.testFunction();

  print('Done');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
