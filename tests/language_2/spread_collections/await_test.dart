// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import 'package:expect/expect.dart';

final list = [1, 2, 3, 4, 5];
final map = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5};
final set = {1, 2, 3, 4, 5};

void main() {
  asyncTest(() async {
    await testList();
    await testMap();
    await testSet();
  });
}

Future<void> testList() async {
  var future12 = Future.value([1, 2]);
  var future45 = Future.value([4, 5]);
  var futureNull = Future.value(null);

  // Await in spread.
  Expect.listEquals(list, [...await future12, 3, ...await future45]);

  // Await in null-aware spread.
  Expect.listEquals(list, [...?await future12, 3, ...?await futureNull, 4, 5]);
}

Future<void> testMap() async {
  var future12 = Future.value({1: 1, 2: 2});
  var future45 = Future.value({4: 4, 5: 5});
  var futureNull = Future.value(null);

  // Await in spread.
  Expect.mapEquals(map, {...await future12, 3: 3, ...await future45});

  // Await in null-aware spread.
  Expect.mapEquals(map,
      {...?await future12, 3: 3, ...?await futureNull, 4: 4, 5: 5});
}

Future<void> testSet() async {
  var future12 = Future.value([1, 2]);
  var future45 = Future.value([4, 5]);
  var futureNull = Future.value(null);

  // Await in spread.
  Expect.setEquals(set, {...await future12, 3, ...await future45});

  // Await in null-aware spread.
  Expect.setEquals(set, {...?await future12, 3, ...?await futureNull, 4, 5});
}
