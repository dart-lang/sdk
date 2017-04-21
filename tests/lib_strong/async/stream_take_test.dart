// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class A {
  const A();
}

class B extends A {
  const B();
}

/// Stream which emits an error if it's not canceled at the correct time.
///
/// Must be canceled after at most [maxEvents] events.
Stream makeStream(int maxEvents) {
  var c;
  int event = 0;
  bool canceled = false;
  c = new StreamController(onListen: () {
    new Timer.periodic(const Duration(milliseconds: 10), (t) {
      if (canceled) {
        t.cancel();
        return;
      }
      if (event == maxEvents) {
        c.addError("NOT CANCELED IN TIME: $maxEvents");
        c.close();
        t.cancel();
      } else {
        c.add(event++);
      }
    });
  }, onCancel: () {
    canceled = true;
  });
  return c.stream;
}

main() {
  asyncStart();
  tests().then((_) {
    asyncEnd();
  });
}

tests() async {
  await expectThrowsAsync(makeStream(4).take(5).toList(), "5/4");
  await expectThrowsAsync(makeStream(0).take(1).toList(), "1/0");

  Expect.listEquals([0, 1, 2, 3, 4], await makeStream(5).take(5).toList());

  Expect.listEquals([0, 1, 2, 3], await makeStream(5).take(4).toList());

  Expect.listEquals([0], await makeStream(5).take(1).toList());

  Expect.listEquals([], await makeStream(5).take(0).toList());

  Expect.listEquals([], await makeStream(0).take(0).toList());
}

Future expectThrowsAsync(Future computation, String name) {
  return computation.then((_) {
    Expect.fail("$name: Did not throw");
  }, onError: (e, s) {});
}
