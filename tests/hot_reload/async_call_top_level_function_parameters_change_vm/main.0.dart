// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

/// Shows the behavior when async code enqueued before a hot restart runs
/// after the restart and tries to interact with code that has been updated.

bool setBeforeAwait = false;
bool setAfterAwait = false;

int changed(String s) {
  return s.length;
}

Future<int> helper(Future<void> timingControl) async {
  setBeforeAwait = true;
  await timingControl;
  setAfterAwait = true;
  return changed('hello');
}

Future<void> main() async {
  var helperCompleter = Completer<void>();
  var helperFuture = helper(helperCompleter.future);
  Expect.isTrue(setBeforeAwait);
  Expect.isFalse(setAfterAwait);
  await hotReload();
  Expect.isFalse(setAfterAwait);
  helperCompleter.complete();
  var error = await asyncExpectThrows<NoSuchMethodError>(helperFuture);
  Expect.contains(
    "Class 'String' has no instance method '-'",
    error.toString(),
  );
  Expect.isTrue(setAfterAwait);
}
