// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  T id(T x);
}

class B<T> {
  T id(T x) => x;
}

class C = A<int> with B<String>; //# 01: compile-time error
class C = A<int> with B<int>; //# 02: ok

void main() {
  C c = new C(); //# 02: continued
}
