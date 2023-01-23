// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension on dynamic {
  void set call(_) {}
}

class Class {
  void set call(_) {}
}

extension on Class? {
  void call() {}
}

method(Function f1, void Function() f2, Class c1, Class? c2) {
  f1.call(); // Ok.
  f1.call = 0; // Error.
  f2.call(); // Ok.
  f2.call = 0; // Error.
  c1.call = 0; // Ok.
  c1.call(); // Error.
  c2.call = 0; // Error.
  c2.call(); // Ok.
}
