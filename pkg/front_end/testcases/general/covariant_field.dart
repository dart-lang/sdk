// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num invariantField;
  covariant num covariantField;
}

abstract class B implements A {
  get invariantField;
  set invariantField(value);
  get covariantField;
  set covariantField(value);
}

abstract class C implements A {
  int get invariantField; // ok
  void set invariantField(int value) {} // error
  int get covariantField; // ok
  void set covariantField(int value) {} // ok
}

abstract class D implements A {
  int get invariantField; // ok
  void set invariantField(covariant int value) {} // ok
  int get covariantField; // ok
  void set covariantField(covariant int value) {} // ok
}

main() {}
