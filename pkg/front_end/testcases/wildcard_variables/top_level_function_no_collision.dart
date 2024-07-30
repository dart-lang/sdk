// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void fn(_, _) {
  print(_);
}

void fn2(_, _, _) {
  print(_);
}

test() {
  fn(1, 2);
  fn2(1, 2, 3);
}
