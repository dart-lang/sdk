// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test is derived from `runtime/tests/vm/dart/causal_stacks/utils.dart`.

import 'dart:async';

Future<void> throwSync() {
  throw '';
}

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

main() {}
