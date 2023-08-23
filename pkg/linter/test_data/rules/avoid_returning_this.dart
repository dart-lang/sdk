// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N avoid_returning_this`

// ignore_for_file: unused_element

class A {
  int x = 0;
  A badAddOne() {
    x++;
    return this; // LINT
  }

  Object goodAddOne1() { // OK it is ok because it does not return an A type.
    x++;
    return this;
  }

  int goodAddOne2() { // OK
    x++;
    return this.x;
  }
  A getThing() {
    return this; // LINT
  }

  B doSomething() { // OK it is ok because it does not return an A type.
    x++;
    return B();
  }

  A operator +(int n) { // OK it is ok because it is an operator.
    x += n;
    return this;
  }
}

class B extends A{
  @override
  A badAddOne() { // OK it is ok because it is an inherited method.
    x++;
    return this;
  }

  @override
  B doSomething() { // OK it is ok because it is an inherited method.
    x++;
    return this;
  }

  B badAddOne2() {
    x++;
    return this; // LINT
  }

  B badOne3() {
    int a() {
      return 1;
    }
    x = a();
    return this; // LINT
  }

  B badOne4() {
    int a() => 1;
    x = a();
    return this; // LINT
  }

  B badOne5() {
    final a = () {
      return 1;
    };
    x = a();
    return this; // LINT
  }
}

abstract class C<T> {
  T m();
  T get g;
}

class D implements C<D> {
  @override
  D m() { // OK defined in interface
    return this;
  }

  @override
  D get g { // OK defined in interface
    return this;
  }

  D _m() {
    return this; // LINT
  }
}
class E implements C<E> {
  @override
  E m() => this; // OK defined in interface

  @override
  E get g => this; // OK defined in interface

  E _m() => this; // LINT
}

extension Ext on A {
  A ext() => this; // OK
}
