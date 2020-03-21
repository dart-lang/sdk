// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  asyncReturn();
  asyncThrow();
  asyncTryCatch();
  asyncAwait();
  syncStar();
  syncStarYield();
  syncStarYieldStar();
  asyncStar();
  asyncStarYield();
  asyncStarYieldStar();
}

asyncReturn() async {
  return 0;
}

asyncThrow() async {
  throw '';
}

asyncTryCatch() async {
  try {
    throw '';
  } catch (e) {
    print(e);
  }
}

asyncAwait() async {
  await 0;
}

syncStar() sync* {}

syncStarYield() sync* {
  yield 0;
}

syncStarYieldStar() sync* {
  yield* [0, 1];
}

asyncStar() async* {}

asyncStarYield() async* {
  yield 0;
}

asyncStarYieldStar() async* {
  yield* null;
}
