// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stream_controller_async_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'package:test/test.dart';
import 'event_helper.dart';
import 'stream_state_helper.dart';

class A {
  const A();
}

class B extends A {
  const B();
}

main() {
  Events sentEvents = new Events()..close();

  // Make sure that lastWhere allows to return instances of types that are
  // different than the generic type of the stream.
  test("lastWhere with super class", () {
    StreamController c = new StreamController<B>();
    Future f = c.stream.lastWhere((x) => false, defaultValue: () => const A());
    f.then(expectAsync((v) {
      Expect.equals(const A(), v);
    }));
    sentEvents.replay(c);
  });
}
