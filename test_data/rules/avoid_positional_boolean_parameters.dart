// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N avoid_positional_boolean_parameters`

// ignore_for_file: unused_element

class Library {
  void checkRegularBook(String name) {
    _checkBook(name, false);
  }

  void checkPremiumBook(String name) {
    _checkBook(name, true);
  }

  void _checkBook(String name, bool isPremium) {} // OK because it is private.
}

void good({bool a = false}) { // OK
  _good(a);
}

void bad(bool a) {} // LINT

void _good(bool a) {} // OK because it is private.

class A {
  void good({bool a = false}) {} // OK

  void bad(bool a) {} // LINT
}

class B {
  static void good({bool a = false}) {} // OK

  static void bad(bool a) {} // LINT
}

class C {
  late bool value;
  C.good({bool value = false}) { // OK
    this.value = value;
  }

  C.bad(bool a) { // LINT
    this.value = value;
  }

  void operator []=(int index, bool value) { // OK (#803)
  }

  void operator +(bool value) { // OK (#803)
  }

  void operator -(bool value) { // OK (#803)
  }
}

class D {
  bool value;
  D.good({this.value = false}); // OK

  D.bad(this.value); // LINT
}

class E {
  void bad([bool value = false]) {} // LINT

  void good({bool value: true}) {} // OK
}

class F {
  set good(bool value) {} // OK
}

class G {
  G._internal([bool value = false]); // OK because is private
}

class H extends E {
  @override
  void bad([bool value = false]) {} // OK because it has inherited method.
}

abstract class I implements E {
  @override
  void bad([bool value = false]) {} // OK because it has inherited method.
}

void closureAsArgument() {
  final array = <bool>[true, false, true, false];
  array.where((bool e) => e); // OK because is an anonymous function.
}

extension Ext on E {
  void badBad([bool value = false]) {} // LINT
}

extension on E {
  void badBadBad([bool value = false]) {} // LINT
}

typedef J = Function({bool value}); // OK

typedef K = Function(bool value); // LINT
