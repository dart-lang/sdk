// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:native_stack_traces/native_stack_traces.dart';

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
// Scenario: None of the async functions yieled before the throw:
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
  // Listening to an async* doesn't create the usual await-for StreamIterator.
  StreamSubscription ss = asyncStarThrowAsync().listen((Future f) {});
  await ss.asFuture();
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

// Helpers:

// We want lines that either start with a frame index or an async gap marker.
final _lineRE = RegExp(r'^(?:#(?<number>\d+)|<asynchronous suspension>)');

void assertStack(List<String> expects, StackTrace stackTrace,
    [String? debugInfoFilename]) async {
  final original = await Stream.value(stackTrace.toString())
      .transform(const LineSplitter())
      .toList();
  var frames = original;

  // Use the DWARF stack decoder if we're running in --dwarf-stack-traces mode
  // and in precompiled mode (otherwise --dwarf-stack-traces has no effect).
  final decodeTrace = frames.first.startsWith('Warning:');
  if (decodeTrace) {
    Expect.isNotNull(debugInfoFilename);
    final dwarf = Dwarf.fromFile(debugInfoFilename!)!;
    frames = await Stream.fromIterable(original)
        .transform(DwarfStackTraceDecoder(dwarf))
        .where(_lineRE.hasMatch)
        .toList();
  }

  void printFrameInformation() {
    print('RegExps for expected stack:');
    expects.forEach((s) => print('"${s}"'));
    print('');
    if (decodeTrace) {
      print('Non-symbolic actual stack:');
      original.forEach(print);
      print('');
    }
    print('Actual stack:');
    frames.forEach(print);
    print('');
  }

  for (int i = 0; i < expects.length; i++) {
    try {
      Expect.isTrue(i < frames.length,
          'Expected at least ${expects.length} frames, found ${frames.length}');
    } on ExpectException {
      // On failed expect, print full stack for reference.
      printFrameInformation();
      print('Expected line ${i + 1} to be ${expects[i]} but was missing');
      rethrow;
    }
    try {
      Expect.isTrue(RegExp(expects[i]).hasMatch(frames[i]));
    } on ExpectException {
      // On failed expect, print full stack for reference.
      printFrameInformation();
      print('Expected line ${i + 1} to be `${expects[i]}` '
          'but was `${frames[i]}`');
      rethrow;
    }
  }

  try {
    Expect.equals(expects.length, frames.length);
  } on ExpectException {
    // On failed expect, print full stack for reference.
    printFrameInformation();
    rethrow;
  }
}

Future<void> doTestAwait(Future f(), List<String> expectedStack,
    [String? debugInfoFilename]) async {
  // Caller catches exception.
  try {
    await f();
    Expect.fail('No exception thrown!');
  } on String catch (e, s) {
    assertStack(expectedStack, s, debugInfoFilename);
  }
}

Future<void> doTestAwaitThen(Future f(), List<String> expectedStack,
    [String? debugInfoFilename]) async {
  // Caller catches but a then is set.
  try {
    // Passing (e) {} to then() can cause the closure instructions to be
    // dedupped, changing the stack trace to the dedupped owner, so we
    // duplicate the Expect.fail() call in the closure.
    await f().then((e) => Expect.fail('No exception thrown!'));
    Expect.fail('No exception thrown!');
  } on String catch (e, s) {
    assertStack(expectedStack, s, debugInfoFilename);
  }
}

Future<void> doTestAwaitCatchError(Future f(), List<String> expectedStack,
    [String? debugInfoFilename]) async {
  // Caller doesn't catch, but we have a catchError set.
  late StackTrace stackTrace;
  await f().catchError((e, s) {
    stackTrace = s;
  });
  assertStack(expectedStack, stackTrace, debugInfoFilename);
}

// ----
// Test "Suites":
// ----

// For: --no-lazy-async-stacks
Future<void> doTestsNoCausalNoLazy([String? debugInfoFilename]) async {
  final allYieldExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'^#2      _RootZone.runUnary ',
    r'^#3      _FutureListener.handleValue ',
    r'^#4      Future._propagateToListeners.handleValueCallback ',
    r'^#5      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#6      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#7      _microtaskLoop ',
    r'^#8      _startMicrotaskLoop ',
    r'^#9      _runPendingImmediateCallback ',
    r'^#10     _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(allYield, allYieldExpected, debugInfoFilename);
  await doTestAwaitThen(allYield, allYieldExpected, debugInfoFilename);
  await doTestAwaitCatchError(allYield, allYieldExpected, debugInfoFilename);

  final noYieldsExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      noYields3 \(.*/utils.dart:54(:3)?\)$',
    r'^#2      noYields3 \(.*/utils.dart:53(:23)?\)$',
    r'^#3      noYields2 \(.*/utils.dart:50(:9)?\)$',
    r'^#4      noYields2 \(.*/utils.dart:49(:23)?\)$',
    r'^#5      noYields \(.*/utils.dart:46(:9)?\)$',
    r'^#6      noYields \(.*/utils.dart:45(:22)?\)$',
  ];
  await doTestAwait(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#7      doTestAwait ',
            r'^#8      doTestAwait ',
            r'^#9      doTestsNoCausalNoLazy ',
            r'^#10     _RootZone.runUnary ',
            r'^#11     _FutureListener.handleValue ',
            r'^#12     Future._propagateToListeners.handleValueCallback ',
            r'^#13     Future._propagateToListeners ',
            r'^#14     Future._completeWithValue ',
            r'^#15     _completeOnAsyncReturn ',
            r'^#16     doTestAwaitCatchError ',
            r'^#17     _RootZone.runUnary ',
            r'^#18     _FutureListener.handleValue ',
            r'^#19     Future._propagateToListeners.handleValueCallback ',
            r'^#20     Future._propagateToListeners ',
            r'^#21     Future._completeError ',
            r'^#22     _completeOnAsyncError ',
            r'^#23     allYield ',
            r'^#24     _asyncErrorWrapperHelper.errorCallback ',
            r'^#25     _RootZone.runBinary ',
            r'^#26     _FutureListener.handleError ',
            r'^#27     Future._propagateToListeners.handleError ',
            r'^#28     Future._propagateToListeners ',
            r'^#29     Future._completeError ',
            r'^#30     _completeOnAsyncError ',
            r'^#31     allYield2 ',
            r'^#32     _asyncErrorWrapperHelper.errorCallback ',
            r'^#33     _RootZone.runBinary ',
            r'^#34     _FutureListener.handleError ',
            r'^#35     Future._propagateToListeners.handleError ',
            r'^#36     Future._propagateToListeners ',
            r'^#37     Future._completeError ',
            r'^#38     _completeOnAsyncError ',
            r'^#39     allYield3 ',
            r'^#40     _RootZone.runUnary ',
            r'^#41     _FutureListener.handleValue ',
            r'^#42     Future._propagateToListeners.handleValueCallback ',
            r'^#43     Future._propagateToListeners ',
            r'^#44     Future._addListener.<anonymous closure> ',
            r'^#45     _microtaskLoop ',
            r'^#46     _startMicrotaskLoop ',
            r'^#47     _runPendingImmediateCallback ',
            r'^#48     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#7      doTestAwaitThen ',
            r'^#8      doTestAwaitThen ',
            r'^#9      doTestsNoCausalNoLazy ',
            r'^#10     _RootZone.runUnary ',
            r'^#11     _FutureListener.handleValue ',
            r'^#12     Future._propagateToListeners.handleValueCallback ',
            r'^#13     Future._propagateToListeners ',
            r'^#14     Future._completeWithValue ',
            r'^#15     _completeOnAsyncReturn ',
            r'^#16     doTestAwait ',
            r'^#17     _asyncErrorWrapperHelper.errorCallback ',
            r'^#18     _RootZone.runBinary ',
            r'^#19     _FutureListener.handleError ',
            r'^#20     Future._propagateToListeners.handleError ',
            r'^#21     Future._propagateToListeners ',
            r'^#22     Future._completeError ',
            r'^#23     _completeOnAsyncError ',
            r'^#24     noYields ',
            r'^#25     _asyncErrorWrapperHelper.errorCallback ',
            r'^#26     _RootZone.runBinary ',
            r'^#27     _FutureListener.handleError ',
            r'^#28     Future._propagateToListeners.handleError ',
            r'^#29     Future._propagateToListeners ',
            r'^#30     Future._completeError ',
            r'^#31     _completeOnAsyncError ',
            r'^#32     noYields2 ',
            r'^#33     _asyncErrorWrapperHelper.errorCallback ',
            r'^#34     _RootZone.runBinary ',
            r'^#35     _FutureListener.handleError ',
            r'^#36     Future._propagateToListeners.handleError ',
            r'^#37     Future._propagateToListeners ',
            r'^#38     Future._completeError ',
            r'^#39     Future._asyncCompleteError.<anonymous closure> ',
            r'^#40     _microtaskLoop ',
            r'^#41     _startMicrotaskLoop ',
            r'^#42     _runPendingImmediateCallback ',
            r'^#43     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#7      doTestAwaitCatchError ',
            r'^#8      doTestAwaitCatchError ',
            r'^#9      doTestsNoCausalNoLazy ',
            r'^#10     _RootZone.runUnary ',
            r'^#11     _FutureListener.handleValue ',
            r'^#12     Future._propagateToListeners.handleValueCallback ',
            r'^#13     Future._propagateToListeners ',
            r'^#14     Future._completeWithValue ',
            r'^#15     _completeOnAsyncReturn ',
            r'^#16     doTestAwaitThen ',
            r'^#17     _asyncErrorWrapperHelper.errorCallback ',
            r'^#18     _RootZone.runBinary ',
            r'^#19     _FutureListener.handleError ',
            r'^#20     Future._propagateToListeners.handleError ',
            r'^#21     Future._propagateToListeners ',
            r'^#22     Future._completeError ',
            r'^#23     _completeOnAsyncError ',
            r'^#24     noYields ',
            r'^#25     _asyncErrorWrapperHelper.errorCallback ',
            r'^#26     _RootZone.runBinary ',
            r'^#27     _FutureListener.handleError ',
            r'^#28     Future._propagateToListeners.handleError ',
            r'^#29     Future._propagateToListeners ',
            r'^#30     Future._completeError ',
            r'^#31     _completeOnAsyncError ',
            r'^#32     noYields2 ',
            r'^#33     _asyncErrorWrapperHelper.errorCallback ',
            r'^#34     _RootZone.runBinary ',
            r'^#35     _FutureListener.handleError ',
            r'^#36     Future._propagateToListeners.handleError ',
            r'^#37     Future._propagateToListeners ',
            r'^#38     Future._completeError ',
            r'^#39     Future._asyncCompleteError.<anonymous closure> ',
            r'^#40     _microtaskLoop ',
            r'^#41     _startMicrotaskLoop ',
            r'^#42     _runPendingImmediateCallback ',
            r'^#43     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

  final mixedYieldsExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(mixedYields, mixedYieldsExpected, debugInfoFilename);
  await doTestAwaitThen(mixedYields, mixedYieldsExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      mixedYields, mixedYieldsExpected, debugInfoFilename);

  final syncSuffixExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(syncSuffix, syncSuffixExpected, debugInfoFilename);
  await doTestAwaitThen(syncSuffix, syncSuffixExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      syncSuffix, syncSuffixExpected, debugInfoFilename);

  final nonAsyncNoStackExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);
  await doTestAwaitThen(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);

  final asyncStarThrowSyncExpected = const <String>[
    r'^#0      throwSync \(.+/utils.dart:16(:3)?\)$',
    r'^#1      asyncStarThrowSync \(.+/utils.dart:112(:11)?\)$',
    r'^#2      _RootZone.runUnary \(.+\)$',
    r'^#3      _FutureListener.handleValue \(.+\)$',
    r'^#4      Future._propagateToListeners.handleValueCallback \(.+\)$',
    r'^#5      Future._propagateToListeners \(.+\)$',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#6      Future.(_addListener|_prependListeners).<anonymous closure> \(.+\)$',
    r'^#7      _microtaskLoop \(.+\)$',
    r'^#8      _startMicrotaskLoop \(.+\)$',
    r'^#9      _runPendingImmediateCallback \(.+\)$',
    r'^#10     _RawReceivePortImpl._handleMessage \(.+\)$',
  ];
  await doTestAwait(awaitEveryAsyncStarThrowSync, asyncStarThrowSyncExpected,
      debugInfoFilename);
  await doTestAwaitThen(awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected, debugInfoFilename);
  await doTestAwaitCatchError(awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected, debugInfoFilename);

  final asyncStarThrowAsyncExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(awaitEveryAsyncStarThrowAsync, asyncStarThrowAsyncExpected,
      debugInfoFilename);
  await doTestAwaitThen(awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected, debugInfoFilename);
  await doTestAwaitCatchError(awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected, debugInfoFilename);

  final listenAsyncStartExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    // TODO(dart-vm): Figure out why this is inconsistent:
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);
  await doTestAwaitThen(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);

  final customErrorZoneExpected = const <String>[
    r'#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'#2      _rootRunUnary ',
    r'#3      _CustomZone.runUnary ',
    r'#4      _FutureListener.handleValue ',
    r'#5      Future._propagateToListeners.handleValueCallback ',
    r'#6      Future._propagateToListeners ',
    r'#7      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'#8      _rootRun ',
    r'#9      _CustomZone.run ',
    r'#10     _CustomZone.runGuarded ',
    r'#11     _CustomZone.bindCallbackGuarded.<anonymous closure> ',
    r'#12     _microtaskLoop ',
    r'#13     _startMicrotaskLoop ',
    r'#14     _runPendingImmediateCallback ',
    r'#15     _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);
  await doTestAwaitThen(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);

  final awaitTimeoutExpected = const <String>[
    r'#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(awaitTimeout, awaitTimeoutExpected, debugInfoFilename);
  await doTestAwaitThen(awaitTimeout, awaitTimeoutExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      awaitTimeout, awaitTimeoutExpected, debugInfoFilename);

  final awaitWaitExpected = const <String>[
    r'#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^#1      _RootZone.runUnary ',
    r'^#2      _FutureListener.handleValue ',
    r'^#3      Future._propagateToListeners.handleValueCallback ',
    r'^#4      Future._propagateToListeners ',
    r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
    r'^#6      _microtaskLoop ',
    r'^#7      _startMicrotaskLoop ',
    r'^#8      _runPendingImmediateCallback ',
    r'^#9      _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(awaitWait, awaitWaitExpected, debugInfoFilename);
  await doTestAwaitThen(awaitWait, awaitWaitExpected, debugInfoFilename);
  await doTestAwaitCatchError(awaitWait, awaitWaitExpected, debugInfoFilename);

  {
    final expected = const <String>[
      r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
      r'^#1      _RootZone.runUnary ',
      r'^#2      _FutureListener.handleValue ',
      r'^#3      Future._propagateToListeners.handleValueCallback ',
      r'^#4      Future._propagateToListeners ',
      r'^#5      Future.(_addListener|_prependListeners).<anonymous closure> ',
      r'^#6      _microtaskLoop ',
      r'^#7      _startMicrotaskLoop ',
      r'^#8      _runPendingImmediateCallback ',
      r'^#9      _RawReceivePortImpl._handleMessage ',
    ];
    await doTestAwait(futureSyncWhenComplete, expected, debugInfoFilename);
    await doTestAwaitThen(futureSyncWhenComplete, expected, debugInfoFilename);
    await doTestAwaitCatchError(
        futureSyncWhenComplete, expected, debugInfoFilename);
  }
}

// For: --lazy-async-stacks
Future<void> doTestsLazy([String? debugInfoFilename]) async {
  final allYieldExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      allYield2 \(.*/utils.dart:34(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#3      allYield \(.*/utils.dart:29(:3)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      allYield,
      allYieldExpected +
          const <String>[
            r'^#4      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#5      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      allYield,
      allYieldExpected +
          const <String>[
            r'^#4      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(allYield, allYieldExpected, debugInfoFilename);

  final noYieldsExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      noYields3 \(.*/utils.dart:54(:3)?\)$',
    r'^#2      noYields2 \(.*/utils.dart:50(:9)?\)$',
    r'^#3      noYields \(.*/utils.dart:46(:9)?\)$',
  ];
  await doTestAwait(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#4      doTestAwait ',
            r'^#5      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitThen ',
            r'^#5      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitCatchError ',
            r'^#5      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);

  final mixedYieldsExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      mixedYields2 \(.*/utils.dart:66(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      mixedYields \(.*/utils.dart:61(:3)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      mixedYields,
      mixedYieldsExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      mixedYields,
      mixedYieldsExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      mixedYields, mixedYieldsExpected, debugInfoFilename);

  final syncSuffixExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      syncSuffix2 \(.*/utils.dart:82(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      syncSuffix \(.*/utils.dart:77(:3)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      syncSuffix,
      syncSuffixExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      syncSuffix,
      syncSuffixExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      syncSuffix, syncSuffixExpected, debugInfoFilename);

  final nonAsyncNoStackExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      nonAsyncNoStack1 \(.*/utils.dart:95(:36)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      nonAsyncNoStack \(.*/utils.dart:93(:35)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      nonAsyncNoStack,
      nonAsyncNoStackExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      nonAsyncNoStack,
      nonAsyncNoStackExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);

  final asyncStarThrowSyncExpected = const <String>[
    r'^#0      throwSync \(.+/utils.dart:16(:3)?\)$',
    r'^#1      asyncStarThrowSync \(.+/utils.dart:112(:11)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      awaitEveryAsyncStarThrowSync \(.+/utils.dart:104(:3)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected, debugInfoFilename);

  final asyncStarThrowAsyncExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      asyncStarThrowAsync \(.*/utils.dart:126(:5)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      awaitEveryAsyncStarThrowAsync \(.+/utils.dart:117(:3)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected, debugInfoFilename);

  final listenAsyncStartExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      asyncStarThrowAsync \(.*/utils.dart:126(:5)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      listenAsyncStarThrowAsync.<anonymous closure> \(.+/utils.dart(:0)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);
  await doTestAwaitThen(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      listenAsyncStarThrowAsync, listenAsyncStartExpected, debugInfoFilename);

  final customErrorZoneExpected = const <String>[
    r'#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'<asynchronous suspension>$',
    r'#2      allYield2 \(.*/utils.dart:34(:3)?\)$',
    r'<asynchronous suspension>$',
    r'#3      allYield \(.*/utils.dart:29(:3)?\)$',
    r'<asynchronous suspension>$',
    r'#4      customErrorZone.<anonymous closure> \(.*/utils.dart:144(:5)?\)$',
    r'<asynchronous suspension>$',
  ];
  await doTestAwait(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);
  await doTestAwaitThen(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      customErrorZone, customErrorZoneExpected, debugInfoFilename);

  final awaitTimeoutExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      Future.timeout.<anonymous closure> \(dart:async/future_impl.dart',
    r'^<asynchronous suspension>$',
    r'^#2      awaitTimeout ',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      awaitTimeout,
      awaitTimeoutExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitTimeout,
      awaitTimeoutExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      awaitTimeout, awaitTimeoutExpected, debugInfoFilename);

  final awaitWaitExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      Future.wait.<anonymous closure> \(dart:async/future.dart',
    r'^<asynchronous suspension>$',
    r'^#2      awaitWait ',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      awaitWait,
      awaitWaitExpected +
          const <String>[
            r'^#3      doTestAwait ',
            r'^<asynchronous suspension>$',
            r'^#4      doTestsLazy ',
            r'^<asynchronous suspension>$',
            r'^#5      main ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitWait,
      awaitWaitExpected +
          const <String>[
            r'^#3      doTestAwaitThen.<anonymous closure> ',
            r'^<asynchronous suspension>$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(awaitWait, awaitWaitExpected, debugInfoFilename);

  {
    final expected = const <String>[
      r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
      r'^<asynchronous suspension>$',
    ];
    await doTestAwait(
        futureSyncWhenComplete,
        expected +
            const <String>[
              r'^#1      doTestAwait ',
              r'^<asynchronous suspension>$',
              r'^#2      doTestsLazy ',
              r'^<asynchronous suspension>$',
              r'^#3      main ',
              r'^<asynchronous suspension>$',
            ],
        debugInfoFilename);
    await doTestAwaitThen(
        futureSyncWhenComplete,
        expected +
            const <String>[
              r'^#1      doTestAwaitThen.<anonymous closure> ',
              r'^<asynchronous suspension>$',
            ],
        debugInfoFilename);
    await doTestAwaitCatchError(
        futureSyncWhenComplete, expected, debugInfoFilename);
  }
}
