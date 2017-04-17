// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// When an exception is thrown in the finally block cleaning up after a cancel,
// the future returned from cancel should complete with an error.

foo() async* {
  try {
    int i = 0;
    while (true) {
      yield i++;
    }
  } finally {
    throw "Error";
  }
}

test() async {
  var completer = new Completer();
  var s;
  s = foo().listen((e) async {
    Expect.equals(0, e);
    try {
      await s.cancel();
      Expect.fail("Did not throw");
    } catch (e) {
      Expect.equals("Error", e);
      completer.complete();
    }
  });
  await completer.future;
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
