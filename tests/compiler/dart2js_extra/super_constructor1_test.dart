// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String message;

class A {
  int x;
  A(i) : x = i {
    message = '${message}A($i)';
  }
}

class B extends A {
  int y;
  B(i) : y = i++, super(i + 5) {
    message = '${message}B($i)';
  }
}

class C extends B {
  var z;
  C(i) : super(i * 3), z = i {
    message = '${message}C($i)';
  }
}

main() {
  message = '';
  var c = new C(7);
  Expect.equals(27, c.x);
  Expect.equals(21, c.y);
  Expect.equals(7, c.z);
  Expect.equals('A(27)B(22)C(7)', message);
}
