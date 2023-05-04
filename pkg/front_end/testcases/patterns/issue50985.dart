// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test1(List list) {
  return switch (list) {
    <int>[1, 2, 3, 4, ... var r1] => r1.toString(),
    _ => "default"
  };
}

main() {
  test1([1, 2, 3, 4, 5, 6]);
}