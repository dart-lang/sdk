// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

final list = [1, 2, 3];
final map = {1: 1, 2: 2, 3: 3};
final set = {1, 2, 3};

void main() {
  asyncTest(() async {
    await testList();
    await testMap();
    await testSet();
  });
}

Future<void> testList() async {
  var future123 = Future.value([1, 2, 3]);
  var future1 = Future.value(1);

  // Await in iterable.
  Expect.listEquals(list, [for (var i in await future123) i]);

  // Await in for-in body.
  Expect.listEquals(list, [for (var i in [1, 2, 3]) await Future.value(i)]);

  // Await in initializer.
  Expect.listEquals(list, [for (var i = await future1; i < 4; i++) i]);

  // Await in condition.
  Expect.listEquals(list,
      [for (var i = 1; await Future.value(i < 4); i++) i]);

  // Await in increment.
  Expect.listEquals(list,
      [for (var i = 1; i < 4; await Future(() => i++)) i]);

  // Await in for body.
  Expect.listEquals(list,
      [for (var i = 1; i < 4; i++) await Future.value(i)]);
}

Future<void> testMap() async {
  var future123 = Future.value([1, 2, 3]);
  var future1 = Future.value(1);

  // Await in iterable.
  Expect.mapEquals(map, {for (var i in await future123) i: i});

  // Await in for-in body key.
  Expect.mapEquals(map,
      {for (var i in [1, 2, 3]) await Future.value(i): i});

  // Await in for-in body value.
  Expect.mapEquals(map,
      {for (var i in [1, 2, 3]) i: await Future.value(i)});

  // Await in initializer.
  Expect.mapEquals(map, {for (var i = await future1; i < 4; i++) i: i});

  // Await in condition.
  Expect.mapEquals(map,
      {for (var i = 1; await Future.value(i < 4); i++) i: i});

  // Await in increment.
  Expect.mapEquals(map,
      {for (var i = 1; i < 4; await Future(() => i++)) i: i});

  // Await in for body key.
  Expect.mapEquals(map,
      {for (var i = 1; i < 4; i++) await Future.value(i): i});

  // Await in for body value.
  Expect.mapEquals(map,
      {for (var i = 1; i < 4; i++) i: await Future.value(i)});
}

Future<void> testSet() async {
  var future123 = Future.value([1, 2, 3]);
  var future1 = Future.value(1);

  // Await in iterable.
  Expect.setEquals(set, {for (var i in await future123) i});

  // Await in for-in body.
  Expect.setEquals(set, {for (var i in [1, 2, 3]) await Future.value(i)});

  // Await in initializer.
  Expect.setEquals(set, {for (var i = await future1; i < 4; i++) i});

  // Await in condition.
  Expect.setEquals(set,
      {for (var i = 1; await Future.value(i < 4); i++) i});

  // Await in increment.
  Expect.setEquals(set,
      {for (var i = 1; i < 4; await Future(() => i++)) i});

  // Await in for body.
  Expect.setEquals(set,
      {for (var i = 1; i < 4; i++) await Future.value(i)});
}
