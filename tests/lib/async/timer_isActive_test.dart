// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_minitest.dart';

main() {
  test("timer isActive test", () {
    late Timer t;

    t = new Timer(const Duration(seconds: 1),
        expectAsync0(() => expect(t.isActive, equals(false))));
    expect(t.isActive, equals(true));
  });

  test("periodic timer cancel test", () {
    late Timer t;

    int i = 0;
    void checkActive(Timer timer) {
      expect(t.isActive, equals(true));
      if (i == 2) {
        t.cancel();
        expect(t.isActive, equals(false));
      }
      i++;
    }

    t = new Timer.periodic(
        new Duration(milliseconds: 1), expectAsync1(checkActive, count: 3));
    expect(t.isActive, equals(true));
  });

  test("timer cancel test", () {
    Timer timer = new Timer(
        const Duration(seconds: 15), () => fail("Should not be reached."));
    Timer.run(expectAsync0(() {
      expect(timer.isActive, equals(true));
      timer.cancel();
      expect(timer.isActive, equals(false));
    }));
  });
}
