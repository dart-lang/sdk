// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  if (x case <num>[1, 2, < 3]) {
    return 0;
  }
  if (x case <String?>[var a, String b?, == "bar"]) {
    return 1;
  }
  if (x case [<String?>[var a?, var b], 0]) {
    return 2;
  }
  if (x case [[[var a?]]]) {
    return 3;
  }
  if (x case [1, 2, 3]?) {
    return 4;
  }
}

test2(List<Object?> x) {
  if (x case <num>[1, 2, < 3]) {
    return 0;
  }
  if (x case <String?>[var a, String b?, == "bar"]) {
    return 1;
  }
  if (x case [<String?>[var a?, var b], 0]) {
    return 2;
  }
  if (x case [[[var a?]]]) {
    return 3;
  }
  if (x case [1, 2, 3]?) {
    return 4;
  }
}

main() {}
