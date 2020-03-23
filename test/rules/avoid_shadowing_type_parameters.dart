// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_shadowing_type_parameters`
void fn1<T>() {
  void fn2<T>() {} // LINT
  void fn3<U>() {} // OK
  void fn4() {} // OK
}

// TODO(srawlins): Lint on this stuff as well when the analyzer/language(?)
// support it. Right now analyzer spits out a compile time error: "Analysis of
// generic function typed parameters is not yet supported."
// void fn2<T>(void Function<T>()) {} // NOT OK

class A<T> {
  static void fn1<T>() {} // OK
}

extension Ext<T> on A<T> {
  void fn2<T>() {} // LINT
  void fn3<U>() {} // OK
  void fn4<V>() {} // OK
}

mixin M<T> {
  void fn1<T>() {} // LINT
  void fn2<U>() {} // OK
  void fn3<V>() {} // OK
}

class B<T> {
  void fn1<T>() {} // LINT
  void fn2<U>() {} // OK
  void fn3<V>() {} // OK
}

class C<T> {
  void fn1<U>() {
    void fn2<T>() {} // LINT
    void fn3<U>() {} // LINT
    void fn4<V>() {} // OK
    void fn5() {} // OK
  }
}

class D<T> {
  void fn1<U>() {
    void fn2<V>() {
      void fn3<T>() {} // LINT
      void fn4<U>() {} // LINT
      void fn5<V>() {} // LINT
      void fn6<W>() {} // OK
      void fn7() {} // OK
    }
  }
}

// Make sure we don't hit any null pointers when none of a function or method's
// ancestors have type parameters.
class E {
  void fn1() {
    void fn2() {
      void fn3<T>() {} // OK
    }
  }

  void fn4<T>() {} // OK
}

typedef Fn1<T> = void Function<T>(T); // LINT
typedef Fn2<T> = void Function<U>(T); // OK
typedef Fn3<T> = void Function<U>(U); // OK
typedef Fn4<T> = void Function(T); // OK
typedef Fn5 = void Function<T>(T); // OK

typedef Predicate = bool <E>(E element); // OK
