// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int get property => 42;
  void set property(int value) {}
}

extension on Class? {
  int get property => 42;
}

void test(Class? c) {
  c.property;
}
