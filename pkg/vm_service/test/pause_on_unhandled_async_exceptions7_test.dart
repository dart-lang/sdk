// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

// Verifies that debugger does not pause when exception is caught by stream
// onError.
//
// Regression test for https://github.com/dart-lang/sdk/issues/54788.
import 'dart:async';
import 'dart:io';

import 'package:stack_trace/stack_trace.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

import 'pause_on_unhandled_async_exceptions6_test.dart' as test6;

Future<int> alwaysThrow() async {
  // Ensure that we suspend at least once and throw an error asynchronously.
  await Future.delayed(Duration.zero);
  print(StackTrace.current);
  throw 'Error';
}

Future<void> throwSomeCaughtAsyncErrors() async {
  await test6.testeeMain(shouldTestUncaught: false);
  try {
    await Future.error('Error!').then((value) => value);
  } catch (_) {
    // Ignore.
  }
  await Future.error('Error!').then((value) => value).catchError((_) {});
  await Future.error('Error!')
      .asStream()
      .asBroadcastStream()
      .first
      .catchError((_) {});
  print('await');
  try {
    await alwaysThrow();
  } catch (_) {
    // Ignore.
  }

  print('records');
  try {
    await (alwaysThrow(), alwaysThrow()).wait;
  } catch (_) {
    // Ignore.
  }

  print('mapped');
  for (var makeStream in test6.streamFactories) {
    await makeStream('Error!')
        .map((v) => v)
        .toList()
        .catchError((_) => <int>[]);
  }

  print('http request');
  final client = HttpClient();
  try {
    final rq = await client.get('invalid.invalid', 80, '/index.html');
    await rq.close();
  } catch (_) {
    // Ignore.
  } finally {
    client.close();
  }

  {
    print('ignoring an error (1)');
    final c = Completer<void>();
    // Here async unwinder might follow awaiter chain to `await c.future`
    // because it detects forwarding automatically.
    alwaysThrow().whenComplete(c.complete).ignore();
    await c.future;
  }

  {
    print('ignoring an error (2)');
    final c = Completer<void>();
    alwaysThrow().whenComplete(() {
      c.complete();
    }).ignore();
    await c.future;
  }
}

Future<void> testeeMain() async {
  await throwSomeCaughtAsyncErrors();
  await Chain.capture(() async {
    await throwSomeCaughtAsyncErrors();
  });

  // This test verifies that we behave conservatively: if we can't unwind
  // the async stack because `Zone` does not cooperate with us we treat
  // exception as caught.
  await runInOpaqueZone(() async {
    await throwSomeCaughtAsyncErrors();
  });

  throw 'LastUncaughtException';
}

R runInOpaqueZone<R>(R Function() body) {
  final zone = Zone.current.fork(
    specification: ZoneSpecification(
      registerUnaryCallback: _registerUnaryCallback,
      registerBinaryCallback: _registerBinaryCallback,
    ),
  );
  return zone.run(body);
}

ZoneUnaryCallback<R, T> _registerUnaryCallback<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T) f) {
  return parent.registerUnaryCallback(zone, (v) => f(v));
}

ZoneBinaryCallback<R, T1, T2> _registerBinaryCallback<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T1, T2) f) {
  return parent.registerBinaryCallback(zone, (a, b) => f(a, b));
}

final tests = [
  expectUnhandledExceptionWithFrames(
    exceptionAsString: 'LastUncaughtException',
  ),
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_unhandled_async_exceptions7_test.dart',
      pauseOnUnhandledExceptions: true,
      testeeConcurrent: testeeMain,
    );
