// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=
// VMOptions=--use_compactor
// VMOptions=--use_compactor --force_evacuation

import 'dart:async';

import 'package:expect/expect.dart';

import 'helpers.dart';

void main() async {
  await testFinalizerZone();
  await testFinalizerException();
}

Future<void> testFinalizerZone() async {
  Zone? expectedZone;
  Zone? actualZone;

  final finalizer = runZoned(() {
    expectedZone = Zone.current;

    void callback(Object token) {
      actualZone = Zone.current;
    }

    return Finalizer<Nonce>(callback);
  });

  final detach = Nonce(2022);
  final token = Nonce(42);

  makeObjectWithFinalizer(finalizer, token, detach: detach);

  doGC();

  // We haven't stopped running synchronous dart code yet.
  Expect.isNull(actualZone);

  await yieldToMessageLoop();

  // Now we have.
  Expect.equals(expectedZone, actualZone);

  // Make sure finalizer is still reachable.
  reachabilityFence(finalizer);
}

Future<void> testFinalizerException() async {
  Object? caughtError;

  final finalizer = runZonedGuarded(() {
    void callback(Object token) {
      throw 'uncaught!';
    }

    return Finalizer<Nonce>(callback);
  }, (Object error, StackTrace stack) {
    caughtError = error;
  })!;

  final detach = Nonce(2022);
  final token = Nonce(42);

  makeObjectWithFinalizer(finalizer, token, detach: detach);

  doGC();

  Expect.isNull(caughtError);
  await yieldToMessageLoop();
  Expect.isNotNull(caughtError);

  // Make sure finalizer is still reachable.
  reachabilityFence(finalizer);
}
