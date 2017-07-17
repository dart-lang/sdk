// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_final_fields`

class FalsePositiveWhenReturn {
  int _value = 0;
  int getValue() {
    return ++_value; // OK
  }
}

class BadImmutable {
  var _label = 'hola mundo! BadImmutable'; // LINT
  var label = 'hola mundo! BadImmutable'; // OK
}

class GoodImmutable {
  final label = 'hola mundo! BadImmutable', bla = 5; // OK
  final _label = 'hola mundo! BadImmutable', _bla = 5; // OK
}

class GoodMutable {
  var _label = 'hola mundo! GoodMutable';
  var _someInt = 0;
  var _otherInt = 1;

  void changeLabel() {
    _label = 'hello world! GoodMutable';
    _someInt++;
    _otherInt += 2;
  }
}

class MultipleMutable {
  final int _someOther;
  var _label = 'hola mundo! GoodMutable', _offender = 'mumble mumble!'; // LINT
  var _never_initialized_field; // OK

  MultipleMutable.foo() : _someOther = 5;

  MultipleMutable(this._someOther);

  void changeLabel() {
    _label = 'hello world! GoodMutable';
  }
}

class C {
  int _f = 0; // LINT
  void m() {
    String _f;
    _f = '';
  }
}

class D {
  int _f = 0; // OK
}

void accessD_f() {
  D d = new D();
  d._f = 42;
}

class E {
  int _f = 0; // LINT

  void useItInRightHandSide() {
    // ignore: unused_local_variable
    int a = _f;
  }
}

class F{
  var _array = new List<int>(5); // LINT

  void foo() {
    _array[0] = 3;
  }
}

// https://github.com/dart-lang/linter/issues/686
class IdBug686 {
  static int _id = 0;
  static String generateId({prefix: String}) {
    return (prefix ?? "id") + "-" +
        (_id++).toString() + "-" + _foo();
  }

  static String _foo() => '';
}
