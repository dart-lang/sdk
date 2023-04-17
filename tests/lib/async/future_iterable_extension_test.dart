// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import '../../language/static_type_helper.dart';

void main() async {
  asyncStart();
  var futures = [for (var i = 0; i < 5; i++) Future<int>.value(i)];
  var errors = [for (var i = 0; i < 5; i++) Future<int>.error("e$i")..ignore()];

  // Empty list.
  Expect.listEquals([], await <Future<int>>[].wait);

  // Single future.
  Expect.listEquals([0], await <Future<int>>[futures[0]].wait);

  // Multiple future.
  Expect.listEquals([0, 1, 2, 3, 4], await futures.wait);

  // Single error.
  try {
    await [futures[0], futures[1], errors[2], futures[3], futures[4]].wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.equals(0, e.values[0]);
    Expect.equals(1, e.values[1]);
    Expect.isNull(e.values[2]);
    Expect.equals(3, e.values[3]);
    Expect.equals(4, e.values[4]);

    Expect.isNull(e.errors[0]);
    Expect.isNull(e.errors[1]);
    Expect.equals("e2", e.errors[2]?.error);
    Expect.isNull(e.errors[3]);
    Expect.isNull(e.errors[4]);
  }

  // Multiple errors.
  try {
    await [futures[0], errors[1], futures[2], errors[3], futures[4]].wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.equals(0, e.values[0]);
    Expect.isNull(e.values[1]);
    Expect.equals(2, e.values[2]);
    Expect.isNull(e.values[3]);
    Expect.equals(4, e.values[4]);

    Expect.isNull(e.errors[0]);
    Expect.equals("e1", e.errors[1]?.error);
    Expect.isNull(e.errors[2]);
    Expect.equals("e3", e.errors[3]?.error);
    Expect.isNull(e.errors[4]);
  }

  // All errors.
  try {
    await errors.wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.isNull(e.values[0]);
    Expect.isNull(e.values[1]);
    Expect.isNull(e.values[2]);
    Expect.isNull(e.values[3]);
    Expect.isNull(e.values[4]);

    Expect.equals("e0", e.errors[0]?.error);
    Expect.equals("e1", e.errors[1]?.error);
    Expect.equals("e2", e.errors[2]?.error);
    Expect.equals("e3", e.errors[3]?.error);
    Expect.equals("e4", e.errors[4]?.error);
  }
  asyncEnd();
}
