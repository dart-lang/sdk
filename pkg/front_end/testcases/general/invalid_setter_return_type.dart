// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int set setter1(_) {} // error
dynamic set setter2(_) {} // error
void set setter3(_) {} // ok
set setter4(_) {} // ok

class Class1 {
  int set setter1(_) {} // error
  int operator []=(a, b) {} // error
}

class Class2 {
  dynamic set setter2(_) {} // error
  dynamic operator []=(a, b) {} // error
}

class Class3 {
  void set setter3(_) {} // ok
  void operator []=(a, b) {} // ok
}

class Class4 {
  set setter4(_) {} // ok
  operator []=(a, b) {} // ok
}

main() {}
