// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;
}

extension Extension on Class {
  int get property => field;
  void set property(int value) {
    field = value;
  }
  int method() => field;
}

main() {
  Class c;
  c?.property ?? 0;
  Extension(c)?.property ?? 0;
  c?.property = 42 ?? 0;
  Extension(c)?.property = 42 ?? 0;
  (c?.property = 42) ?? 0;
  (Extension(c)?.property = 42) ?? 0;
  c?.method() ?? 0;
  Extension(c)?.method() ?? 0;
  c = new Class();
  c.property ?? 0;
  Extension(c).property ?? 0;
}
