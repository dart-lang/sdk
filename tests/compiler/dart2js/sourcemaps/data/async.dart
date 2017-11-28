// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  asyncReturn();
  asyncThrow();
  asyncTryCatch();
  asyncAwait();
  syncStarYield();
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

syncStarYield() sync* {
  yield 0;
}
