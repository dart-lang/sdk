// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String foo(String s) {
  print(s);
  return s;
}

test() {
  String a = foo("a"), _ = foo("b"), c = foo("c"), _ = foo("d");
}
