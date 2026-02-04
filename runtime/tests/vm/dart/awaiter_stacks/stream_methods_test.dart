// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

// This test check that awaiter stack unwinding can produce useful and readable
// stack traces when unwinding through various built-in [Stream] methods.
import 'dart:async';

import 'package:expect/expect.dart';
import 'harness.dart' as harness;

Future<void> baz() async {
  // Check stack trace once before async suspension point.
  await harness.checkExpectedStack(StackTrace.current);
  // Check stack trace once after suspension point.
  await harness.checkExpectedStack(StackTrace.current);
}

Stream<String> bar() async* {
  await harness.checkExpectedStack(StackTrace.current);
  await baz();
  yield "";
}

Stream<String> foo() async* {
  await harness.checkExpectedStack(StackTrace.current);
  await baz();
  yield* bar();
  await baz();
}

Stream<String> Function() stream(Iterable<String> elements) {
  return () => Stream.fromIterable(elements);
}

Future<void> runTest(
  Future<void> Function(Stream<String> stream) body, {
  Stream<String> Function() source = foo,
  bool expectedToThrow = false,
}) async {
  try {
    await body(source());
  } catch (e, st) {
    Expect.isTrue(expectedToThrow, 'Not expecting exception');
    await harness.checkExpectedStack(st);
  }
}

Future<void> main() async {
  if (harness.shouldSkip()) {
    return;
  }

  harness.configure(currentExpectations);

  await runTest((s) => s.reduce((a, b) => ''));
  await runTest((s) => s.fold('', (a, b) => ''));
  await runTest((s) => s.join(''));
  await runTest((s) => s.contains(''));
  await runTest((s) => s.forEach((v) {}));
  await runTest((s) => s.every((v) => true));
  await runTest((s) => s.any((v) => false));
  await runTest((s) => s.length);
  await runTest((s) => s.isEmpty);
  await runTest((s) => s.toList());
  await runTest((s) => s.toSet());
  await runTest((s) => s.first);
  await runTest((s) => s.last);
  await runTest((s) => s.single);
  await runTest((s) => s.singleWhere((element) => true));
  await runTest((s) => s.firstWhere((element) => true));
  await runTest((s) => s.lastWhere((element) => true));
  await runTest((s) => s.elementAt(0));

  // Check that error caused by empty stream also produces good stack traces.
  await runTest(
    (s) => s.reduce((a, b) => ''),
    source: stream([]),
    expectedToThrow: true,
  );
  await runTest((s) => s.first, source: stream([]), expectedToThrow: true);
  await runTest((s) => s.last, source: stream([]), expectedToThrow: true);
  await runTest((s) => s.single, source: stream([]), expectedToThrow: true);
  await runTest(
    (s) => s.single,
    source: stream(['1', '2']),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.single,
    source: stream(['1', '2']),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.singleWhere((_) => true),
    source: stream([]),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.singleWhere((_) => true),
    source: stream(['1', '2']),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.firstWhere((element) => true),
    source: stream([]),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.lastWhere((element) => true),
    source: stream([]),
    expectedToThrow: true,
  );
  await runTest(
    (s) => s.elementAt(0),
    source: stream([]),
    expectedToThrow: true,
  );

  harness.updateExpectations();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.fold.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.join.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.contains.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.forEach.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.every.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.any.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.length.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.isEmpty.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toList.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.toSet.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    foo (%test%)
<asynchronous suspension>
#1    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#2    runTest (%test%)
<asynchronous suspension>
#3    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    bar (%test%)
<asynchronous suspension>
#1    foo (%test%)
<asynchronous suspension>
#2    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#3    runTest (%test%)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    baz (%test%)
<asynchronous suspension>
#1    bar (%test%)
<asynchronous suspension>
#2    foo (%test%)
<asynchronous suspension>
#3    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#4    runTest (%test%)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.reduce.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.first.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.last.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.single.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.singleWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.singleWhere.<anonymous closure>.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.firstWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.lastWhere.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
  """
#0    Stream.elementAt.<anonymous closure> (stream.dart)
<asynchronous suspension>
#1    runTest (%test%)
<asynchronous suspension>
#2    main (%test%)
<asynchronous suspension>""",
];
// CURRENT EXPECTATIONS END
