// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int id) {
  abstract int m; /* Error */
}

extension type ET2<T>(T id) {
  T get getter; /* Error */
}

extension type ET3(int id) {
  void setter(int x); /* Error */
}

extension type ET4<T>(T id) {
  void method(); /* Error */
}

extension type ET5(int id) {
  int operator +(int other); /* Error */
}

class A {
  int x();
  dynamic noSuchMethod(Invocation invocation) => null;
}

extension type ET6(A id) implements A {
  int method(); /* Error */

  int get getter; /* Error */

  void set setter(int v); /* Error */
}

extension E on A {
  abstract int m; /* Error */

  int method(); /* Error */

  int get getter; /* Error */

  void set setter(int v); /* Error */
}