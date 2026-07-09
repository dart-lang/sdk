// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List makeList(List list) => list;

Stream makeStream(List list) async* {
  for (var e in list) {
    yield e;
  }
}

test() async {
  for (String i in makeList([1, 2, 3])) {
    print(i);
  }
  await for (String i in makeStream([1, 2, 3])) {
    print(i);
  }
}

main() async {
  for (int i in makeList([1, 2, 3])) {
    print(i);
  }
  await for (int i in makeStream([1, 2, 3])) {
    print(i);
  }
}
