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
  throw '';
}

Future<void> throwAsync() async {
  await 0;
  throw '';
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
    final dwarf = Dwarf.fromFile(debugInfoFilename!);
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
    await f().then((e) {
      // Ignore.
    });
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

// For: --causal-async-stacks
Future<void> doTestsCausal([String? debugInfoFilename]) async {
  final allYieldExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      allYield2 \(.*/utils.dart:34(:9)?\)$',
    r'^<asynchronous suspension>$',
    r'^#3      allYield \(.*/utils.dart:29(:9)?\)$',
    r'^<asynchronous suspension>$',
  ];
  await doTestAwait(
      allYield,
      allYieldExpected +
          const <String>[
            r'^#4      doTestAwait ',
            r'^#5      doTestsCausal ',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      allYield,
      allYieldExpected +
          const <String>[
            r'^#4      doTestAwaitThen ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      allYield,
      allYieldExpected +
          const <String>[
            r'^#4      doTestAwaitCatchError ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

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
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitThen ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitCatchError ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

  final mixedYieldsExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      mixedYields3 \(.*/utils.dart:70(:10)?\)$',
    r'^#2      mixedYields2 \(.*/utils.dart:66(:9)?\)$',
    r'^<asynchronous suspension>$',
    r'^#3      mixedYields \(.*/utils.dart:61(:9)?\)$',
  ];
  await doTestAwait(
      mixedYields,
      mixedYieldsExpected +
          const <String>[
            r'^#4      doTestAwait ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      mixedYields,
      mixedYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitThen ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      mixedYields,
      mixedYieldsExpected +
          const <String>[
            r'^#4      doTestAwaitCatchError ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

  final syncSuffixExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      syncSuffix3 \(.*/utils.dart:86(:10)?\)$',
    r'^#2      syncSuffix2 \(.*/utils.dart:82(:9)?\)$',
    r'^<asynchronous suspension>$',
    r'^#3      syncSuffix \(.*/utils.dart:77(:9)?\)$',
  ];
  await doTestAwait(
      syncSuffix,
      syncSuffixExpected +
          const <String>[
            r'^#4      doTestAwait ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      syncSuffix,
      syncSuffixExpected +
          const <String>[
            r'^#4      doTestAwaitThen ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      syncSuffix,
      syncSuffixExpected +
          const <String>[
            r'^#4      doTestAwaitCatchError ',
            r'^#5      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#6      main ',
            r'^#7      _startIsolate.<anonymous closure> ',
            r'^#8      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

  final nonAsyncNoStackExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      nonAsyncNoStack2.<anonymous closure> ',
    r'^#2      _RootZone.runUnary ',
    r'^#3      _FutureListener.handleValue ',
    r'^#4      Future._propagateToListeners.handleValueCallback ',
    r'^#5      Future._propagateToListeners ',
    r'^#6      Future._completeWithValue ',
    r'^#7      Future._asyncCompleteWithValue.<anonymous closure> ',
    r'^#8      _microtaskLoop ',
    r'^#9      _startMicrotaskLoop ',
    r'^#10     _runPendingImmediateCallback ',
    r'^#11     _RawReceivePortImpl._handleMessage ',
  ];
  await doTestAwait(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);
  await doTestAwaitThen(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);
  await doTestAwaitCatchError(
      nonAsyncNoStack, nonAsyncNoStackExpected, debugInfoFilename);

  final asyncStarThrowSyncExpected = const <String>[
    r'^#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'^#1      asyncStarThrowSync \(.*/utils.dart:112(:11)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      awaitEveryAsyncStarThrowSync \(.+\)$',
  ];
  await doTestAwait(
      awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected +
          const <String>[
            r'^#3      doTestAwait \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected +
          const <String>[
            r'^#3      doTestAwaitThen \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      awaitEveryAsyncStarThrowSync,
      asyncStarThrowSyncExpected +
          const <String>[
            r'^#3      doTestAwaitCatchError \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);

  final asyncStarThrowAsyncExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      asyncStarThrowAsync \(.*/utils.dart:126(:11)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      awaitEveryAsyncStarThrowAsync \(.+\)$',
  ];
  await doTestAwait(
      awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected +
          const <String>[
            r'^#3      doTestAwait \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected +
          const <String>[
            r'^#3      doTestAwaitThen \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      awaitEveryAsyncStarThrowAsync,
      asyncStarThrowAsyncExpected +
          const <String>[
            r'^#3      doTestAwaitCatchError \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);

  final listenAsyncStartExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^<asynchronous suspension>$',
    r'^#1      asyncStarThrowAsync \(.*/utils.dart:126(:11)?\)$',
    r'^<asynchronous suspension>$',
    r'^#2      listenAsyncStarThrowAsync \(.+/utils.dart:132(:27)?\)$',
  ];
  await doTestAwait(
      listenAsyncStarThrowAsync,
      listenAsyncStartExpected +
          const <String>[
            r'^#3      doTestAwait \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      listenAsyncStarThrowAsync,
      listenAsyncStartExpected +
          const <String>[
            r'^#3      doTestAwaitThen \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      listenAsyncStarThrowAsync,
      listenAsyncStartExpected +
          const <String>[
            r'^#3      doTestAwaitCatchError \(.+\)$',
            r'^#4      doTestsCausal \(.+\)$',
            r'^<asynchronous suspension>$',
            r'^#5      main \(.+\)$',
            r'^#6      _startIsolate.<anonymous closure> \(.+\)$',
            r'^#7      _RawReceivePortImpl._handleMessage \(.+\)$',
          ],
      debugInfoFilename);

  final customErrorZoneExpected = const <String>[
    r'#0      throwSync \(.*/utils.dart:16(:3)?\)$',
    r'#1      allYield3 \(.*/utils.dart:39(:3)?\)$',
    r'<asynchronous suspension>$',
    r'#2      allYield2 \(.*/utils.dart:34(:9)?\)$',
    r'<asynchronous suspension>$',
    r'#3      allYield \(.*/utils.dart:29(:9)?\)$',
    r'<asynchronous suspension>$',
    r'#4      customErrorZone.<anonymous closure> \(.*/utils.dart:144(:11)?\)$',
    r'#5      _rootRun ',
    r'#6      _CustomZone.run ',
    r'#7      _runZoned ',
    r'#8      runZonedGuarded ',
    r'#9      customErrorZone \(.*/utils.dart:143(:3)?\)$',
  ];
  await doTestAwait(
      customErrorZone,
      customErrorZoneExpected +
          const <String>[
            r'#10     doTestAwait ',
            r'#11     doTestsCausal ',
            r'<asynchronous suspension>$',
            r'#12     main \(.+\)$',
            r'#13     _startIsolate.<anonymous closure> ',
            r'#14     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      customErrorZone,
      customErrorZoneExpected +
          const <String>[
            r'#10     doTestAwaitThen ',
            r'#11     doTestsCausal ',
            r'<asynchronous suspension>$',
            r'#12     main \(.+\)$',
            r'#13     _startIsolate.<anonymous closure> ',
            r'#14     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      customErrorZone,
      customErrorZoneExpected +
          const <String>[
            r'#10     doTestAwaitCatchError ',
            r'#11     doTestsCausal ',
            r'<asynchronous suspension>$',
            r'#12     main \(.+\)$',
            r'#13     _startIsolate.<anonymous closure> ',
            r'#14     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);

  final awaitTimeoutExpected = const <String>[
    r'^#0      throwAsync \(.*/utils.dart:21(:3)?\)$',
    r'^^<asynchronous suspension>$',
    r'^#1      awaitTimeout ',
  ];
  await doTestAwait(
      awaitTimeout,
      awaitTimeoutExpected +
          const <String>[
            r'^#2      doTestAwait ',
            r'^#3      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#4      main \(.+\)$',
            r'^#5      _startIsolate.<anonymous closure> ',
            r'^#6      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      awaitTimeout,
      awaitTimeoutExpected +
          const <String>[
            r'^#2      doTestAwaitThen ',
            r'^#3      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#4      main \(.+\)$',
            r'^#5      _startIsolate.<anonymous closure> ',
            r'^#6      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      awaitTimeout,
      awaitTimeoutExpected +
          const <String>[
            r'^#2      doTestAwaitCatchError ',
            r'^#3      doTestsCausal ',
            r'^<asynchronous suspension>$',
            r'^#4      main \(.+\)$',
            r'^#5      _startIsolate.<anonymous closure> ',
            r'^#6      _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
}

// For: --no-causal-async-stacks --no-lazy-async-stacks
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
    r'^#2      _AsyncAwaitCompleter.start ',
    r'^#3      noYields3 \(.*/utils.dart:53(:23)?\)$',
    r'^#4      noYields2 \(.*/utils.dart:50(:9)?\)$',
    r'^#5      _AsyncAwaitCompleter.start ',
    r'^#6      noYields2 \(.*/utils.dart:49(:23)?\)$',
    r'^#7      noYields \(.*/utils.dart:46(:9)?\)$',
    r'^#8      _AsyncAwaitCompleter.start ',
    r'^#9      noYields \(.*/utils.dart:45(:22)?\)$',
  ];
  await doTestAwait(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#10     doTestAwait ',
            r'^#11     _AsyncAwaitCompleter.start ',
            r'^#12     doTestAwait ',
            r'^#13     doTestsNoCausalNoLazy ',
            r'^#14     _RootZone.runUnary ',
            r'^#15     _FutureListener.handleValue ',
            r'^#16     Future._propagateToListeners.handleValueCallback ',
            r'^#17     Future._propagateToListeners ',
            r'^#18     Future._completeWithValue ',
            r'^#19     _AsyncAwaitCompleter.complete ',
            r'^#20     _completeOnAsyncReturn ',
            r'^#21     doTestAwaitCatchError ',
            r'^#22     _RootZone.runUnary ',
            r'^#23     _FutureListener.handleValue ',
            r'^#24     Future._propagateToListeners.handleValueCallback ',
            r'^#25     Future._propagateToListeners ',
            r'^#26     Future._completeError ',
            r'^#27     _AsyncAwaitCompleter.completeError ',
            r'^#28     allYield ',
            r'^#29     _asyncErrorWrapperHelper.errorCallback ',
            r'^#30     _RootZone.runBinary ',
            r'^#31     _FutureListener.handleError ',
            r'^#32     Future._propagateToListeners.handleError ',
            r'^#33     Future._propagateToListeners ',
            r'^#34     Future._completeError ',
            r'^#35     _AsyncAwaitCompleter.completeError ',
            r'^#36     allYield2 ',
            r'^#37     _asyncErrorWrapperHelper.errorCallback ',
            r'^#38     _RootZone.runBinary ',
            r'^#39     _FutureListener.handleError ',
            r'^#40     Future._propagateToListeners.handleError ',
            r'^#41     Future._propagateToListeners ',
            r'^#42     Future._completeError ',
            r'^#43     _AsyncAwaitCompleter.completeError ',
            r'^#44     allYield3 ',
            r'^#45     _RootZone.runUnary ',
            r'^#46     _FutureListener.handleValue ',
            r'^#47     Future._propagateToListeners.handleValueCallback ',
            r'^#48     Future._propagateToListeners ',
            // TODO(dart-vm): Figure out why this is inconsistent:
            r'^#49     Future.(_addListener|_prependListeners).<anonymous closure> ',
            r'^#50     _microtaskLoop ',
            r'^#51     _startMicrotaskLoop ',
            r'^#52     _runPendingImmediateCallback ',
            r'^#53     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitThen(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#10     doTestAwaitThen ',
            r'^#11     _AsyncAwaitCompleter.start ',
            r'^#12     doTestAwaitThen ',
            r'^#13     doTestsNoCausalNoLazy ',
            r'^#14     _RootZone.runUnary ',
            r'^#15     _FutureListener.handleValue ',
            r'^#16     Future._propagateToListeners.handleValueCallback ',
            r'^#17     Future._propagateToListeners ',
            r'^#18     Future._completeWithValue ',
            r'^#19     _AsyncAwaitCompleter.complete ',
            r'^#20     _completeOnAsyncReturn ',
            r'^#21     doTestAwait ',
            r'^#22     _asyncErrorWrapperHelper.errorCallback ',
            r'^#23     _RootZone.runBinary ',
            r'^#24     _FutureListener.handleError ',
            r'^#25     Future._propagateToListeners.handleError ',
            r'^#26     Future._propagateToListeners ',
            r'^#27     Future._completeError ',
            r'^#28     _AsyncAwaitCompleter.completeError ',
            r'^#29     noYields ',
            r'^#30     _asyncErrorWrapperHelper.errorCallback ',
            r'^#31     _RootZone.runBinary ',
            r'^#32     _FutureListener.handleError ',
            r'^#33     Future._propagateToListeners.handleError ',
            r'^#34     Future._propagateToListeners ',
            r'^#35     Future._completeError ',
            r'^#36     _AsyncAwaitCompleter.completeError ',
            r'^#37     noYields2 ',
            r'^#38     _asyncErrorWrapperHelper.errorCallback ',
            r'^#39     _RootZone.runBinary ',
            r'^#40     _FutureListener.handleError ',
            r'^#41     Future._propagateToListeners.handleError ',
            r'^#42     Future._propagateToListeners ',
            r'^#43     Future._completeError ',
            // TODO(dart-vm): Figure out why this is inconsistent:
            r'^#44     Future.(_asyncCompleteError|_chainForeignFuture).<anonymous closure> ',
            r'^#45     _microtaskLoop ',
            r'^#46     _startMicrotaskLoop ',
            r'^#47     _runPendingImmediateCallback ',
            r'^#48     _RawReceivePortImpl._handleMessage ',
          ],
      debugInfoFilename);
  await doTestAwaitCatchError(
      noYields,
      noYieldsExpected +
          const <String>[
            r'^#10     doTestAwaitCatchError ',
            r'^#11     _AsyncAwaitCompleter.start ',
            r'^#12     doTestAwaitCatchError ',
            r'^#13     doTestsNoCausalNoLazy ',
            r'^#14     _RootZone.runUnary ',
            r'^#15     _FutureListener.handleValue ',
            r'^#16     Future._propagateToListeners.handleValueCallback ',
            r'^#17     Future._propagateToListeners ',
            r'^#18     Future._completeWithValue ',
            r'^#19     _AsyncAwaitCompleter.complete ',
            r'^#20     _completeOnAsyncReturn ',
            r'^#21     doTestAwaitThen ',
            r'^#22     _asyncErrorWrapperHelper.errorCallback ',
            r'^#23     _RootZone.runBinary ',
            r'^#24     _FutureListener.handleError ',
            r'^#25     Future._propagateToListeners.handleError ',
            r'^#26     Future._propagateToListeners ',
            r'^#27     Future._completeError ',
            r'^#28     _AsyncAwaitCompleter.completeError ',
            r'^#29     noYields ',
            r'^#30     _asyncErrorWrapperHelper.errorCallback ',
            r'^#31     _RootZone.runBinary ',
            r'^#32     _FutureListener.handleError ',
            r'^#33     Future._propagateToListeners.handleError ',
            r'^#34     Future._propagateToListeners ',
            r'^#35     Future._completeError ',
            r'^#36     _AsyncAwaitCompleter.completeError ',
            r'^#37     noYields2 ',
            r'^#38     _asyncErrorWrapperHelper.errorCallback ',
            r'^#39     _RootZone.runBinary ',
            r'^#40     _FutureListener.handleError ',
            r'^#41     Future._propagateToListeners.handleError ',
            r'^#42     Future._propagateToListeners ',
            r'^#43     Future._completeError ',
            // TODO(dart-vm): Figure out why this is inconsistent:
            r'^#44     Future.(_asyncCompleteError|_chainForeignFuture).<anonymous closure> ',
            r'^#45     _microtaskLoop ',
            r'^#46     _startMicrotaskLoop ',
            r'^#47     _runPendingImmediateCallback ',
            r'^#48     _RawReceivePortImpl._handleMessage ',
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
  await doTestAwait(
      awaitTimeout, awaitTimeoutExpected + const <String>[], debugInfoFilename);
  await doTestAwaitThen(
      awaitTimeout, awaitTimeoutExpected + const <String>[], debugInfoFilename);
  await doTestAwaitCatchError(
      awaitTimeout, awaitTimeoutExpected + const <String>[], debugInfoFilename);
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
    r'^#1      Future.timeout.<anonymous closure> \(dart:async/future_impl.dart\)$',
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
      awaitTimeout, awaitTimeoutExpected + const <String>[], debugInfoFilename);
}
