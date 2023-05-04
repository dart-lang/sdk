// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int _foo = 0;
}

test(dynamic x) {
  switch(x) {
    case A(_foo: 42):
      return x;
    default:
      return null;
  }
}
