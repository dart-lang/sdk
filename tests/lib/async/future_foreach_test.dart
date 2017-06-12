// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library future_foreach_test;

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'dart:async';

main() {
  asyncStart();

  testForeach(<int>[]);
  testForeach(<int>[0]);
  testForeach(<int>[0, 1, 2, 3]);

  testForeachIterableThrows(
      new Iterable<int>.generate(5, (i) => i < 4 ? i : throw "ERROR"),
      4,
      "ERROR");

  testForeachFunctionThrows(new Iterable<int>.generate(5, (x) => x), 4);

  asyncEnd();
}

void testForeach(Iterable<int> elements) {
  for (var delay in [0, 1, 2]) {
    asyncStart();
    int length = elements.length;
    int count = 0;
    int nesting = 0;
    Future.forEach<int>(elements, (int value) {
      Expect.isTrue(nesting == 0, "overlapping calls detected");
      if (delay == 0) return "something-$delay";
      nesting++;
      var future;
      if (delay == 1) {
        future = new Future(() => null);
      } else {
        future = new Future.microtask(() => null);
      }
      return future.then<String>((_) {
        Expect.equals(1, nesting);
        nesting--;
        return "something-$delay";
      });
    }).then((_) {
      asyncEnd();
    }).catchError((e) {
      Expect.fail("Throws: $e");
    });
  }
}

void testForeachIterableThrows(Iterable<int> elements, n, error) {
  for (var delay in [0, 1, 2]) {
    asyncStart();
    int count = 0;
    Future.forEach<int>(elements, (_) {
      count++;
      Expect.isTrue(n >= 0);
      switch (delay) {
        case 1:
          return new Future<String>(() {});
        case 2:
          return new Future<String>.microtask(() {});
      }
    }).then((_) {
      Expect.fail("Did not throw");
    }, onError: (e) {
      Expect.equals(n, count);
      Expect.equals(error, e);
      asyncEnd();
    });
  }
}

void testForeachFunctionThrows(Iterable<int> elements, n) {
  for (var delay in [0, 1, 2]) {
    asyncStart();
    Future.forEach<int>(elements, (v) {
      if (v == n) {
        switch (delay) {
          case 0:
            throw "ERROR";
          case 1:
            return new Future<String>(() {
              throw "ERROR";
            });
          case 2:
            return new Future<String>.microtask(() {
              throw "ERROR";
            });
        }
      }
      switch (delay) {
        case 1:
          return new Future(() {});
        case 2:
          return new Future.microtask(() {});
      }
    }).then((_) {
      Expect.fail("Did not throw");
    }, onError: (e) {
      Expect.equals("ERROR", e);
      asyncEnd();
    });
  }
}
