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
  var futureTrue = Future.value(true);
  var future2 = Future.value(2);
  var future9 = Future.value(9);

  // Await in condition.
  Expect.listEquals(list, [1, if (await futureTrue) 2, 3]);

  // Await in then branch.
  Expect.listEquals(list, [1, if (true) await future2, 3]);

  // Await in else branch.
  Expect.listEquals(list, [1, if (false) 9 else await future2, 3]);

  // Await in untaken then branch.
  Expect.listEquals(list, [1, 2, if (false) await future9, 3]);

  // Await in untaken else branch.
  Expect.listEquals(list, [1, if (true) 2 else await future9, 3]);
}

Future<void> testMap() async {
  var futureTrue = Future.value(true);
  var future2 = Future.value(2);
  var future9 = Future.value(9);

  // Await in condition.
  Expect.mapEquals(map, {1: 1, if (await futureTrue) 2: 2, 3: 3});

  // Await in then branch key.
  Expect.mapEquals(map, {1: 1, if (true) await future2: 2, 3: 3});

  // Await in then branch value.
  Expect.mapEquals(map, {1: 1, if (true) 2: await future2, 3: 3});

  // Await in else branch key.
  Expect.mapEquals(map, {1: 1, if (false) 9: 9 else await future2: 2, 3: 3});

  // Await in else branch value.
  Expect.mapEquals(map, {1: 1, if (false) 9: 9 else 2: await future2, 3: 3});

  // Await in untaken then branch key.
  Expect.mapEquals(map, {1: 1, 2: 2, if (false) await future9: 9, 3: 3});

  // Await in untaken then branch value.
  Expect.mapEquals(map, {1: 1, 2: 2, if (false) 9: await future9, 3: 3});

  // Await in untaken else branch key.
  Expect.mapEquals(map, {1: 1, if (true) 2: 2 else await future9: 9, 3: 3});

  // Await in untaken else branch value.
  Expect.mapEquals(map, {1: 1, if (true) 2: 2 else 9: await future9, 3: 3});
}

Future<void> testSet() async {
  var futureTrue = Future.value(true);
  var future2 = Future.value(2);
  var future9 = Future.value(9);

  // Await in condition.
  Expect.setEquals(set, {1, if (await futureTrue) 2, 3});

  // Await in then branch.
  Expect.setEquals(set, {1, if (true) await future2, 3});

  // Await in else branch.
  Expect.setEquals(set, {1, if (false) 9 else await future2, 3});

  // Await in untaken then branch.
  Expect.setEquals(set, {1, 2, if (false) await future9, 3});

  // Await in untaken else branch.
  Expect.setEquals(set, {1, if (true) 2 else await future9, 3});
}
