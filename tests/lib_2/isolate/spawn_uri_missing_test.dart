// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that Isolate.spanUri completes with an error when the given URI
/// doesn't resolve to an existing resource.
library test.isolate.spawn_uri_missing_test;

import 'dart:isolate';

import 'dart:async';

import 'package:async_helper/async_helper.dart';

const UNEXPECTED_MESSAGE = 'Created isolate from missing file.';

Future doTest() {
  return Isolate
      .spawnUri(Uri.base.resolve('no_such_file'), [], null)
      .then((Isolate isolate) {
    throw UNEXPECTED_MESSAGE;
  }).catchError((error) {
    if (error == UNEXPECTED_MESSAGE) throw error;
    print('An error was thrown as expected');
    return null;
  });
}

main() {
  asyncTest(doTest);
}
