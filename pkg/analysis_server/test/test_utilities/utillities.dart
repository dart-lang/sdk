// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/**
 * Call a test that we think will fail.
 *
 * Ensure that we return any thrown exception correctly (avoiding the
 * package:test zone error handler).
 */
Future callFailingTest(Future Function() expectedFailingTestFn) {
  final Completer completer = new Completer();

  try {
    runZoned(
      () async => await expectedFailingTestFn(),
      onError: (error) {
        completer.completeError(error);
      },
    ).then((result) {
      completer.complete(result);
    }).catchError((error) {
      completer.completeError(error);
    });
  } catch (error) {
    completer.completeError(error);
  }

  return completer.future;
}
