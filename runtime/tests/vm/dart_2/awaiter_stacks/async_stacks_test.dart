// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Note: we pass --save-debugging-info=* without --dwarf-stack-traces to
// make this test pass on vm-aot-dwarf-* builders.
//
// VMOptions=--save-debugging-info=$TEST_COMPILATION_DIR/debug.so
// VMOptions=--dwarf-stack-traces --save-debugging-info=$TEST_COMPILATION_DIR/debug.so

// @dart=2.9

import 'dart:async';

import 'package:expect/expect.dart';

import 'harness.dart' as harness;

// Test functions:

Future<void> throwSync() {
  throw 'throw from throwSync';
}

Future<void> throwAsync() async {
  await 0;
  throw 'throw from throwAsync';
}

// ----
// Scenario: All async functions yielded at least once before throw:
// ----
Future<void> allYield() async {
  await 0;
  await allYield2();
}

Future<void> allYield2() async {
  await 0;
  await allYield3();
}

Future<void> allYield3() async {
  await 0;
  throwSync();
}

// ----
// Scenario: None of the async functions yielded before the throw:
// ----
Future<void> noYields() async {
  await noYields2();
}

Future<void> noYields2() async {
  await noYields3();
}

Future<void> noYields3() async {
  throwSync();
}

// ----
// Scenario: Mixed yielding and non-yielding frames:
// ----
Future<void> mixedYields() async {
  await mixedYields2();
}

Future<void> mixedYields2() async {
  await 0;
  await mixedYields3();
}

Future<void> mixedYields3() async {
  return throwAsync();
}

// ----
// Scenario: Non-async frame:
// ----
Future<void> syncSuffix() async {
  await syncSuffix2();
}

Future<void> syncSuffix2() async {
  await 0;
  await syncSuffix3();
}

Future<void> syncSuffix3() {
  return throwAsync();
}

// ----
// Scenario: Caller is non-async, has no upwards stack:
// ----

Future nonAsyncNoStack() async => await nonAsyncNoStack1();

Future nonAsyncNoStack1() async => await nonAsyncNoStack2();

Future nonAsyncNoStack2() async => Future.value(0).then((_) => throwAsync());

// ----
// Scenario: async*:
// ----

Future awaitEveryAsyncStarThrowSync() async {
  await for (Future v in asyncStarThrowSync()) {
    await v;
  }
}

Stream<Future> asyncStarThrowSync() async* {
  for (int i = 0; i < 2; i++) {
    await i;
    yield throwSync();
  }
}

Future awaitEveryAsyncStarThrowAsync() async {
  await for (Future v in asyncStarThrowAsync()) {
    await v;
  }
}

Stream<Future> asyncStarThrowAsync() async* {
  for (int i = 0; i < 2; i++) {
    await i;
    yield Future.value(i);
    await throwAsync();
  }
}

Future listenAsyncStarThrowAsync() async {
  final _output = [];
  // Listening to an async* doesn't create the usual await-for StreamIterator.
  StreamSubscription ss = asyncStarThrowAsync().listen((Future f) {
    _output.add('unique value');
  });
  await ss.asFuture();
  if (_output.length == 44) {
    print(_output);
  }
}

// ----
// Scenario: All async functions yielded and we run in a custom zone with a
// custom error handler.
// ----

Future<void> customErrorZone() async {
  final completer = Completer<void>();
  runZonedGuarded(() async {
    await allYield();
    completer.complete(null);
  }, (e, s) {
    completer.completeError(e, s);
  });
  return completer.future;
}

// ----
// Scenario: Future.timeout:
// ----

Future awaitTimeout() async {
  await (throwAsync().timeout(Duration(seconds: 1)));
}

// ----
// Scenario: Future.wait:
// ----

Future awaitWait() async {
  await Future.wait([
    throwAsync(),
    () async {
      await Future.value();
    }()
  ]);
}

// ----
// Scenario: Future.whenComplete:
// ----

Future futureSyncWhenComplete() {
  return Future.sync(throwAsync).whenComplete(() => 'nop');
}

// ----
// Scenario: Future.then:
// ----

Future futureThen() {
  return Future.value(0).then((value) {
    throwSync();
  }).then(_doSomething);
}

void _doSomething(_) {
  Expect.fail('Should not reach doSomething');
}

Future<void> doTestAwait(Future f()) async {
  await f();
  Expect.fail('No exception thrown!');
}

Future<void> doTestAwaitThen(Future f()) async {
  // Passing (e) {} to then() can cause the closure instructions to be
  // deduped, changing the stack trace to the deduped owner, so we
  // duplicate the Expect.fail() call in the closure.
  await f().then((e) => Expect.fail('No exception thrown!'));
}

Future<void> doTestAwaitCatchError(Future f()) async {
  Object error;
  StackTrace stackTrace;
  await f().catchError((e, s) {
    error = e;
    stackTrace = s;
  });
  return Future.error(error, stackTrace);
}

Future<void> main(List<String> args) async {
  if (harness.shouldSkip()) {
    return;
  }

  harness.configure(currentExpectations);

  final tests = [
    allYield,
    noYields,
    mixedYields,
    syncSuffix,
    nonAsyncNoStack,
    awaitEveryAsyncStarThrowSync,
    awaitEveryAsyncStarThrowAsync,
    listenAsyncStarThrowAsync,
    customErrorZone,
    awaitTimeout,
    awaitWait,
    futureSyncWhenComplete,
    futureThen,
  ];

  for (var test in tests) {
    await harness.runTest(() => doTestAwait(test));
    await harness.runTest(() => doTestAwaitThen(test));
    await harness.runTest(() => doTestAwaitCatchError(test));
  }

  harness.updateExpectations();
}

// CURRENT EXPECTATIONS BEGIN
final currentExpectations = [
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    doTestAwait (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#5    doTestAwaitThen (%test%)
<asynchronous suspension>
#6    runTest (harness.dart)
<asynchronous suspension>
#7    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    noYields3 (%test%)
#2    noYields2 (%test%)
#3    noYields (%test%)
#4    doTestAwait (%test%)
#5    main.<anonymous closure> (%test%)
#6    runTest (harness.dart)
#7    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    noYields3 (%test%)
#2    noYields2 (%test%)
#3    noYields (%test%)
#4    doTestAwaitThen (%test%)
#5    main.<anonymous closure> (%test%)
#6    runTest (harness.dart)
#7    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    noYields3 (%test%)
#2    noYields2 (%test%)
#3    noYields (%test%)
#4    doTestAwaitCatchError (%test%)
#5    main.<anonymous closure> (%test%)
#6    runTest (harness.dart)
#7    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    mixedYields2 (%test%)
<asynchronous suspension>
#2    mixedYields (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    mixedYields2 (%test%)
<asynchronous suspension>
#2    mixedYields (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    mixedYields2 (%test%)
<asynchronous suspension>
#2    mixedYields (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    syncSuffix2 (%test%)
<asynchronous suspension>
#2    syncSuffix (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    syncSuffix2 (%test%)
<asynchronous suspension>
#2    syncSuffix (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    syncSuffix2 (%test%)
<asynchronous suspension>
#2    syncSuffix (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    nonAsyncNoStack1 (%test%)
<asynchronous suspension>
#2    nonAsyncNoStack (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    nonAsyncNoStack1 (%test%)
<asynchronous suspension>
#2    nonAsyncNoStack (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    nonAsyncNoStack1 (%test%)
<asynchronous suspension>
#2    nonAsyncNoStack (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    asyncStarThrowSync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowSync (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    asyncStarThrowSync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowSync (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    asyncStarThrowSync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowSync (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowAsync (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowAsync (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    awaitEveryAsyncStarThrowAsync (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    listenAsyncStarThrowAsync.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    listenAsyncStarThrowAsync.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    asyncStarThrowAsync (%test%)
<asynchronous suspension>
#2    listenAsyncStarThrowAsync.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    customErrorZone.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    customErrorZone.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    allYield3 (%test%)
<asynchronous suspension>
#2    allYield2 (%test%)
<asynchronous suspension>
#3    allYield (%test%)
<asynchronous suspension>
#4    customErrorZone.<anonymous closure> (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.timeout.<anonymous closure> (future_impl.dart)
<asynchronous suspension>
#2    awaitTimeout (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.timeout.<anonymous closure> (future_impl.dart)
<asynchronous suspension>
#2    awaitTimeout (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.timeout.<anonymous closure> (future_impl.dart)
<asynchronous suspension>
#2    awaitTimeout (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.wait.<anonymous closure> (future.dart)
<asynchronous suspension>
#2    awaitWait (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.wait.<anonymous closure> (future.dart)
<asynchronous suspension>
#2    awaitWait (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    Future.wait.<anonymous closure> (future.dart)
<asynchronous suspension>
#2    awaitWait (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    futureSyncWhenComplete.<anonymous closure> (%test%)
<asynchronous suspension>
#2    doTestAwait (%test%)
<asynchronous suspension>
#3    runTest (harness.dart)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    futureSyncWhenComplete.<anonymous closure> (%test%)
<asynchronous suspension>
#2    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#3    doTestAwaitThen (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwAsync (%test%)
<asynchronous suspension>
#1    futureSyncWhenComplete.<anonymous closure> (%test%)
<asynchronous suspension>
#2    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#3    runTest (harness.dart)
<asynchronous suspension>
#4    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    futureThen.<anonymous closure> (%test%)
<asynchronous suspension>
#2    _doSomething (%test%)
<asynchronous suspension>
#3    doTestAwait (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    futureThen.<anonymous closure> (%test%)
<asynchronous suspension>
#2    _doSomething (%test%)
<asynchronous suspension>
#3    doTestAwaitThen.<anonymous closure> (%test%)
<asynchronous suspension>
#4    doTestAwaitThen (%test%)
<asynchronous suspension>
#5    runTest (harness.dart)
<asynchronous suspension>
#6    main (%test%)
<asynchronous suspension>""",
  """
#0    throwSync (%test%)
#1    futureThen.<anonymous closure> (%test%)
<asynchronous suspension>
#2    _doSomething (%test%)
<asynchronous suspension>
#3    doTestAwaitCatchError (%test%)
<asynchronous suspension>
#4    runTest (harness.dart)
<asynchronous suspension>
#5    main (%test%)
<asynchronous suspension>"""
];
// CURRENT EXPECTATIONS END
