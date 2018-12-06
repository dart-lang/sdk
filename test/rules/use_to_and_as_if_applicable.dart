// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N use_to_and_as_if_applicable`

class A {
  A.from(B);
}

// Testing the regexp
class B {
  A foo() { // LINT
    return new A.from(this);
  }

  A toA() { // OK
    return new A.from(this);
  }

  A asA() { // OK
    return new A.from(this);
  }

  A toList() { // OK
    return new A.from(this);
  }

  A asMyFavoriteClass() { // OK
    return new A.from(this);
  }

  A toa() { // LINT
    return new A.from(this);
  }

  A asa() { // LINT
    return new A.from(this);
  }

  A _foo() { // LINT
    return new A.from(this);
  }

  A _toA() { // OK
    return new A.from(this);
  }

  A _asA() { // OK
    return new A.from(this);
  }

  A _toa() { // LINT
    return new A.from(this);
  }

  A _asa() { // LINT
    return new A.from(this);
  }

  A _functionWihParameter(int a) { // OK
    return new A.from(this);
  }

  // delete not used functions lints.
  void deleteLints() {
    _foo();
    _toA();
    _asA();
    _toa();
    _asa();
    _functionWihParameter(0);
  }
}
