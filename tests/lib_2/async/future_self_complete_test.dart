// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

void main() async {
  asyncStart();
  var completer = Completer<int>();
  // Should complete with error, but not synchronously.
  completer.complete(completer.future);
  await completer.future.then((value) {
    Expect.fail("Completed with value $value.");
  }, onError: (e, _) {
    Expect.type<UnsupportedError>(e);
  }).timeout(const Duration(milliseconds: 1), onTimeout: () {
    Expect.fail("Did not complete");
  });

  // Also if going through indirections.
  var completer1 = Completer<int>();
  var completer2 = Completer<int>();

  // Should complete with error, but not synchronously.
  completer1.complete(completer2.future);
  completer2.complete(completer1.future);

  completer1.future.ignore();
  completer2.future.ignore();
  await completer1.future.then((value) {
    Expect.fail("Completed with value $value.");
  }, onError: (e, _) {
    Expect.type<UnsupportedError>(e);
  }).timeout(const Duration(milliseconds: 1), onTimeout: () {
    Expect.fail("Did not complete");
  });

  await completer2.future.then((value) {
    Expect.fail("Completed with value $value.");
  }, onError: (e, _) {
    Expect.type<UnsupportedError>(e);
  }).timeout(const Duration(milliseconds: 1), onTimeout: () {
    Expect.fail("Did not complete");
  });

  // Also if coming from a callback.
  completer1 = Completer<int>();
  completer2 = Completer<int>();
  completer2.complete(completer1.future.then((_) => completer2.future));
  completer1.complete(1);
  await completer2.future.then((value) {
    Expect.fail("Completed with value $value.");
  }, onError: (e, _) {
    Expect.type<UnsupportedError>(e);
  }).timeout(const Duration(milliseconds: 1), onTimeout: () {
    Expect.fail("Did not complete");
  });

  asyncEnd();
}
