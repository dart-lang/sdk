// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 12;
const String file = "step_through_constructor_calls_test.dart";

code() {
  Foo foo1 = new Foo();
  print(foo1.x);
  Foo foo2 = new Foo.named();
  print(foo2.x);
  Foo foo3 = const Foo();
  print(foo3.x);
  Foo foo4 = const Foo.named();
  print(foo4.x);
  Foo foo5 = new Foo.named2(1, 2, 3);
  print(foo5.x);
}

class Foo {
  final int x;

  const Foo() : x = 1;

  const Foo.named() : x = 2;

  const Foo.named2(int aaaaaaaa, int bbbbbbbbbb, int ccccccccccccc)
      : x = aaaaaaaa + bbbbbbbbbb + ccccccccccccc;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:18", // on 'Foo'
  "$file:${LINE+15}:12", // on '(' in 'const Foo() : x = 1;'
  "$file:${LINE+15}:22", // on ';' in same line
  "$file:${LINE+1}:14", // on 'x'
  "$file:${LINE+1}:3", // on print
  "$file:${LINE+2}:18", // on 'Foo'
  "$file:${LINE+17}:18", // on '(' in 'const Foo.named() : x = 2;'
  "$file:${LINE+17}:28", // on ';' in same line
  "$file:${LINE+3}:14", // on 'x'
  "$file:${LINE+3}:3", // on print
  "$file:${LINE+4}:12", // on '='
  "$file:${LINE+5}:14", // on 'x'
  "$file:${LINE+5}:3", // on print
  "$file:${LINE+6}:12", // on '='
  "$file:${LINE+7}:14", // on 'x'
  "$file:${LINE+7}:3", // on print
  "$file:${LINE+8}:18", // on 'Foo'
  "$file:${LINE+19}:54", // on 'ccccccccccccc'
  "$file:${LINE+20}:22", // on first '+'
  "$file:${LINE+20}:35", // on second '+'
  "$file:${LINE+20}:50", // on ';'
  "$file:${LINE+9}:14", // on 'x'
  "$file:${LINE+9}:3", // on print
  "$file:${LINE+10}:1" // on ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepIntoThroughProgramRecordingStops(stops),
  // removeDuplicates: Source-based debugging stops on the ';'
  // in the constructors twice. Kernel does not. For now we'll accept that.
  checkRecordedStops(stops, expected, removeDuplicates: true)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
