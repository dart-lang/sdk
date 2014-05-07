// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.cancelable_future_test;

import 'dart:async';

import 'package:barback/src/utils.dart';
import 'package:barback/src/utils/cancelable_future.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  var completer;
  var future;
  setUp(() {
    completer = new Completer();
    future = new CancelableFuture(completer.future);
  });

  group("when not canceled", () {
    test("correctly completes successfully", () {
      expect(future, completion(equals("success")));
      completer.complete("success");
    });

    test("correctly completes with an error", () {
      expect(future, throwsA(equals("error")));
      completer.completeError("error");
    });
  });

  group("when canceled", () {
    test("never completes successfully", () {
      var completed = false;
      future.whenComplete(() {
        completed = true;
      });

      future.cancel();
      completer.complete("success");

      expect(pumpEventQueue().then((_) => completed), completion(isFalse));
    });

    test("never completes with an error", () {
      var completed = false;
      future.catchError((_) {}).whenComplete(() {
        completed = true;
      });

      future.cancel();
      completer.completeError("error");

      expect(pumpEventQueue().then((_) => completed), completion(isFalse));
    });
  });
}
