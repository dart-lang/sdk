// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ClassWithOperators {
  ClassWithOperators o;
  int i;
  String s;
  bool b;
  var untyped;

  ClassWithOperators() {}

  int operator[] (int i) {
    return 0;
  }

  ClassWithOperators operator +(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator -(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator *(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator /(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator ~/(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator %(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator <(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator >(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator <=(ClassWithOperators operand) {
    return this;
  }

  ClassWithOperators operator >=(ClassWithOperators operand) {
    return this;
  }

  bool operator ==(other) {
    return false;
  }
}
