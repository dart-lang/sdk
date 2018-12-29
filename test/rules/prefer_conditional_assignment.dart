// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_conditional_assignment`

String getFullUserName(Person person) {
  // Something expensive
  return null;
}

class Person {
  int x;
  String _fullName;

  void badWithBlock1() {
    if (_fullName == null) { // LINT
      _fullName = getFullUserName(this);
    }
  }

  void badWithBlock2() {
    if ((_fullName) == (null)) { // LINT
      _fullName = getFullUserName(this);
    }
  }

  void badWithBlock3() {
    if ((_fullName == null)) { // LINT
      _fullName = getFullUserName(this);
    }
  }

  String get badWithMultipleBlocks1 {
    if (_fullName == null) { // LINT
      {
        _fullName = getFullUserName(this);
      }
    }
    return _fullName;
  }

  String get badWithMultipleBlocks2 {
    if ((_fullName) == (null)) { // LINT
      {
        _fullName = getFullUserName(this);
      }
    }
    return _fullName;
  }

  String get badWithMultipleBlocks3 {
    if ((_fullName == null)) { // LINT
      {
        _fullName = getFullUserName(this);
      }
    }
    return _fullName;
  }

  String get badWithoutBlock1 {
    if (_fullName == null) // LINT
      _fullName = getFullUserName(this);
    return _fullName;
  }

  String get badWithoutBlock2 {
    if ((_fullName) == (null)) // LINT
      _fullName = getFullUserName(this);
    return _fullName;
  }

  String get badWithoutBlock3 {
    if ((_fullName == null)) // LINT
      _fullName = getFullUserName(this);
    return _fullName;
  }

  void good1() {
    if (_fullName == null) {
      x = 0;
    }
  }

  void good2() {
    if (_fullName == null) {
      x = 0;
    }
  }

  void good3() {
    if (_fullName == null) {
      x = 0;
      _fullName = getFullUserName(this);
    }
  }

  void goodBecauseHasElseStatement1() {
    if (_fullName == null) { // OK
      _fullName = getFullUserName(this);
    } else {}
  }

  void goodBecauseHasElseStatement2() {
    if ((_fullName) == (null)) { // OK
      _fullName = getFullUserName(this);
    } else {}
  }

  void goodBecauseHasElseStatement3() {
    if ((_fullName == null)) { // OK
      _fullName = getFullUserName(this);
    } else {}
  }

  A a;
  A b;

  void f() {
    if (a.i == null) { // OK
      b.i = 7;
    }
  }

  void g() {
    if (a.i == null) { // LINT
      a.i = 7;
    }
  }
}

class A {
  int i;
}
