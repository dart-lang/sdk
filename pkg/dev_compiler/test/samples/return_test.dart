// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic a = 42;

// This requires a check / unbox.
int get b => a;

// This requires a type check.
String c() => a;

d() {
  return a;
}

// This requires a type check.
String e() {
  return a;
}

class A {
  A.named();

  factory A() => a;
}

void main() {
  print(a);
  print(b);
  a = "Hello";
  print(c());
  print(d());
  print(e());
  a = new A.named();
  print(new A());
}
