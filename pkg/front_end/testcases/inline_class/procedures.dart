// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Class {
  final int it;

  void instanceMethod() {
    var local = this;
    var localM = instanceMethod();
    var localT = instanceMethod;
    var localG = instanceGetter;
  }

  int get instanceGetter => 42;

  void instanceMethod2(String s, [int i = 42]) {
    var local = this;
    var localS = s;
    var localI = i;
    var localG1 = genericInstanceMethod(s);
    var localG2 = genericInstanceMethod(i);
    var localG3 = genericInstanceMethod<num>(i);
  }

  S genericInstanceMethod<S>(S s) => s;

  static void staticMethod() {
    staticMethod();
    var localG1 = genericStaticMethod(0);
    var localG2 = genericStaticMethod('');
    var localG3 = genericStaticMethod<num>(0);
  }

  static S genericStaticMethod<S>(S s) => s;
}

inline class GenericClass<T> {
  final T it;

  void instanceMethod() {
    var local = this;
    var localM = instanceMethod();
    var localT = instanceMethod;
    var localG = instanceGetter;
  }

  T get instanceGetter => throw '';

  void instanceMethod2(String s, {int i = 42}) {
    var local = this;
    var localS = s;
    var localI = i;
    var localG1 = genericInstanceMethod(s);
    var localG2 = genericInstanceMethod(i);
    var localG3 = genericInstanceMethod<num>(i);
  }

  S genericInstanceMethod<S>(S s) => s;

  static void staticMethod() {
    staticMethod();
    var localG1 = genericStaticMethod(0);
    var localG2 = genericStaticMethod('');
    var localG3 = genericStaticMethod<num>(0);
  }

  static S genericStaticMethod<S>(S s) => s;
}
