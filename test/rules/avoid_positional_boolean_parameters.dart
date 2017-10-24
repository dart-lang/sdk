// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_positional_boolean_parameters`

class Library {
  void checkRegularBook(String name) {
    _checkBook(name, false);
  }

  void checkPremiumBook(String name) {
    _checkBook(name, true);
  }

  void _checkBook(String name, bool isPremium) {} // OK because it is private.
}


void good({bool a}) { // OK
  _good(a);
}

void bad(bool a) {} // LINT

void _good(bool a) {} // OK because it is private.

class A {
  void good({bool a}) {} // OK

  void bad(bool a) {} // LINT
}

class B {
  static void good({bool a}) {} // OK

  static void bad(bool a) {} // LINT
}

class C {
  bool value;
  C.good({bool value}) { // OK
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
  D.good({this.value}); // OK

  D.bad(this.value); // LINT
}

class E {
  void bad([bool value]) {} // LINT

  void good({bool value: true}) {} // OK
}

class F {
  set good(bool value) {} // OK
}

class G {
  G._internal([bool value]); // OK because is private
}

class H extends E {
  @override
  void bad([bool value]) {} // OK because it has inherited method.
}

void closureAsArgument() {
  final array = <bool>[true, false, true, false];
  array.where((bool e) => e); // OK because is an anonymous function.
}
