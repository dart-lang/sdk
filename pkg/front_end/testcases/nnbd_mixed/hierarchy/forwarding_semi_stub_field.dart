// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  num field1 = 0;
  num field2 = 0;
  num field3 = 0;

  covariant num field4 = 0;
  covariant int field5 = 0;
}

class Interface {
  covariant int field1 = 0;
  covariant int field2 = 0;

  int field4 = 0;
  int field5 = 0;
}

class Class extends Super implements Interface {
  abstract int field1;
  abstract String field2;
  abstract int field3;

  abstract int field4;
  abstract num field5;
}

main() {}
