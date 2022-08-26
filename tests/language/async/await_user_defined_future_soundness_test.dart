// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that a user-defined Future cannot provide a value of incorrect
// type by casting 'onValue' callback.
// Regression test for https://github.com/dart-lang/sdk/issues/49345.

import 'dart:async';

import "package:expect/expect.dart";

List<String> executionTrace = <String>[];

Future<void> foo(Future<String> f) async {
  executionTrace.add('Checkpoint 1');
  final String result = await f;
  executionTrace.add('Checkpoint 3');
  print(result.runtimeType);
}

// Immediately calls onValue callback with an ill-typed argument.
class CustomFuture1 implements Future<String> {
  Future<R> then<R>(FutureOr<R> Function(String) onValue, {Function? onError}) {
    executionTrace.add('Checkpoint 2');
    final result = (onValue as FutureOr<R> Function(dynamic))(10);
    executionTrace.add('Checkpoint 4');
    return Future.value(result);
  }

  @override
  dynamic noSuchMethod(i) => throw UnimplementedError();
}

// Schedules microtask to call onValue callback with an ill-typed argument.
class CustomFuture2<S, T> implements Future<T> {
  final Completer done = Completer();
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    scheduleMicrotask(() {
      Expect.throws(() {
        executionTrace.add('Checkpoint 2');
        (onValue as FutureOr<R> Function(dynamic))(10);
        executionTrace.add('Checkpoint 4');
      });
      done.complete();
    });
    return Future<R>.value();
  }

  @override
  dynamic noSuchMethod(i) => throw UnimplementedError();
}

void main() async {
  bool seenError = false;
  runZoned(() {
    foo(CustomFuture1());
  }, onError: (e, st) {
    seenError = true;
  });
  Expect.listEquals(<String>['Checkpoint 1', 'Checkpoint 2'], executionTrace);
  Expect.isTrue(seenError);

  executionTrace.clear();
  final customFuture2 = CustomFuture2<int, String>();
  foo(customFuture2);
  await customFuture2.done.future;
  Expect.listEquals(<String>['Checkpoint 1', 'Checkpoint 2'], executionTrace);
}
