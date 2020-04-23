// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/33166
void main() async {
  // Check that a `null` data handler (like the one passe by `drain`)
  // doesn't crash.
  {
    var stream = new Stream<Object>.fromIterable([1, 2, 3]);
    Expect.equals(await stream.cast<int>().drain().then((_) => 'Done'), 'Done');
  }

  // Check that type errors go into stream error channel.
  {
    var stream = new Stream<Object>.fromIterable([1, 2, 3]);
    var errors = [];
    var done = new Completer();
    var subscription = stream.cast<String>().listen((value) {
      Expect.fail("Unexpected value: $value");
    }, onError: (e, s) {
      errors.add(e);
    }, onDone: () {
      done.complete(null);
    });
    await done.future;
    Expect.equals(3, errors.length);
  }
}
