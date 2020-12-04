// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int value;
  C() : value = 0 {}
  init() {
    value = 0;
  }

  int get id => value;
  void set id(int v) {
    this.value = v;
  }
}

extension Ext on C {
  int get id => this.value + 1;
}

test() {
  C c = C();
  Ext(c).id++;
}

main() {}
