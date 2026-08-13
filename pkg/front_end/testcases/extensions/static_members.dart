// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {}

extension A2 on A1 {
  static A1 method1(A1 o) => o;

  static T method2<T>(T o) => o;
}

class B1<T> {}

extension B2<T> on B1<T> {
  static B1 method1(B1 o) => o;

  static S method2<S>(S o) => o;
}

main() {}
