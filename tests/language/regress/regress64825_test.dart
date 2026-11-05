// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for http://dartbug.com/64825.
//
// When the return type of a generator function literal or local function is
// inferred from its body, a `yield*` statement whose operand has type `dynamic`
// contributes `dynamic` to the element type, and one whose operand has type
// `Never` contributes `Never`.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:expect/static_type_helper.dart';

void testSyncStarDynamic(dynamic d) {
  var f = () sync* {
    yield 1;
    yield* d;
  };
  f.expectStaticType<Exactly<Iterable<dynamic> Function()>>();
  // Since the element type is `dynamic`, this is a dynamic call.
  Expect.equals(3, f().last.length);
}

void testSyncStarDynamicLocalFunction(dynamic d) {
  g() sync* {
    yield 1;
    yield* d;
  }

  g.expectStaticType<Exactly<Iterable<dynamic> Function()>>();
  Expect.equals(3, g().last.length);
}

void testSyncStarDynamicWithContext(dynamic d) {
  // The context type still determines the element type.
  Iterable<num> Function() f = () sync* {
    yield* d;
  };
  Expect.type<Iterable<num> Function()>(f);
}

void testSyncStarNever() {
  var f = () sync* {
    yield* (throw 'unreachable');
  };
  f.expectStaticType<Exactly<Iterable<Never> Function()>>();
}

Future<void> testAsyncStarDynamic(dynamic s) async {
  var f = () async* {
    yield 1;
    yield* s;
  };
  f.expectStaticType<Exactly<Stream<dynamic> Function()>>();
  // Since the element type is `dynamic`, this is a dynamic call.
  Expect.equals(3, (await f().last).length);
}

void testAsyncStarNever() {
  var f = () async* {
    yield* (throw 'unreachable');
  };
  f.expectStaticType<Exactly<Stream<Never> Function()>>();
}

void main() {
  testSyncStarDynamic(['abc']);
  testSyncStarDynamicLocalFunction(['abc']);
  testSyncStarDynamicWithContext(<num>[1, 2.5]);
  testSyncStarNever();
  testAsyncStarNever();
  asyncTest(() => testAsyncStarDynamic(Stream.value('abc')));
}
