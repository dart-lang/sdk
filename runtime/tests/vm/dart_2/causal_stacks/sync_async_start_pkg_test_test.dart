// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test ensures that "pkg:stack_trace" (used by "pkg:test") doesn't break
// when causal async stacks are enabled by dropping frames below a synchronous
// start to an async function.

import "package:test/test.dart";
import "package:stack_trace/src/stack_zone_specification.dart";

import 'dart:async';

void main() {
  test("Stacktrace includes sync-starts.", () async {
    final st = await firstMethod();
    expect("$st", allOf([contains("firstMethod"), contains("secondMethod")]));
  });
}

Future<StackTrace> firstMethod() async {
  return await secondMethod();
}

Future<StackTrace> secondMethod() async {
  return StackTrace.current;
}
