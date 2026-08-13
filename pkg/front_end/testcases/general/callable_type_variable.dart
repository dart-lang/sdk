// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1<T extends Function> {
  T field;

  Class1(this.field);

  method() {
    var v1 = field(); // ok
    var v2 = field(0); // ok
    var v3 = field.call; // ok
    var v4 = field.call(); // ok
    var v5 = field.call(0); // ok
  }
}

class Class2<T extends String Function(int)> {
  T field;

  Class2(this.field);

  method() {
    var v1 = field(); // error
    var v2 = field(0); // ok
    var v3 = field.call; // ok
    var v4 = field.call(); // error
    var v5 = field.call(0); // ok
  }
}

main() {}
