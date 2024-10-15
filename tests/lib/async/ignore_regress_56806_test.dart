// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

// Regression test for http://dartbug.com/56806
//
// Checks that `.ignore()` gets propagated correctly when chaining futures.

void main() async {
  asyncStart();

  await testNoThrow();

  asyncStart();
  await runZoned(testDoThrow, zoneSpecification: ZoneSpecification(
      handleUncaughtError: (s, p, z, Object error, StackTrace stack) {
    asyncEnd();
  }));

  asyncEnd();
}

Future<void> testNoThrow() async {
  var completer = Completer<void>();
  final future = Future<void>.delayed(
      Duration.zero, () => throw StateError("Should be ignored"));
  var future2 = future.whenComplete(() async {
    await Future.delayed(Duration.zero);
    completer.complete();
  });
  future2.ignore(); // Has no listeners.
  await completer.future;
}

Future<void> testDoThrow() async {
  var completer = Completer<void>();
  final future = Future<void>.delayed(
      Duration.zero, () => throw StateError("Should not be ignored"));
  future.ignore(); // Ignores error only on `future`.
  future.whenComplete(() async {
    await Future.delayed(Duration.zero);
    completer.complete();
  }); // Should rethrow the error, as uncaught.
  await completer.future;
}
