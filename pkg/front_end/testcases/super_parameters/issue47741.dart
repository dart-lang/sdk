// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(int foo<T>(int a));
}

class B extends A {
  B.sub1(double super.bar1<T1>(int a1),);
  B.sub2(double super.bar2<T2>(int a2),);
}

main() {}
