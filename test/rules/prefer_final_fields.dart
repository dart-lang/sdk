// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_final_fields`

//ignore_for_file: unused_field, unused_local_variable, prefer_expression_function_bodies

class PrefixOps {
  bool _initialized = false; // LINT
  int _num = 1; // LINT
  int _num2 = 1; // OK
  int _bits = 0xffff; // LINT
  int getValue() {
    if (!_initialized) {
      return 0;
    }
    if (-_num  == -1) {
      return 0;
    }
    if (~_bits == 0) {
      return 0;
    }
    if (--_num2  == 0) {
      return 0;
    }
    return 1;
  }
}

typedef bool Predicate();

class PostfixOps {
  int _num = 1; // OK
  int _num2 = 1; // OK
  String _string = ''; // LINT

  Predicate _predicate = () => false; // LINT

  int getValue() {
    if (_num--  == -1) {
      return 0;
    }
    if (_num2++  == 1) {
      return 0;
    }
    if (_predicate()) {
      return 1;
    }
    if (_string.length == 1) {
      return 0;
    }
    return 1;
  }
}

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

class BadMultipleFormals {
  var _label; // LINT
  BadMultipleFormals(this._label);
  BadMultipleFormals.withDefault(this._label);
}

class BadInitializer {
  var _label; // LINT
  BadInitializer() : _label = 'Hello';
}

class BadMultipleInitializer {
  var _label; // LINT
  BadMultipleInitializer() : _label = 'Hello';
  BadMultipleInitializer.withDefault() : _label = 'Default';
}

class BadMultipleMixConstructors {
  var _label; // LINT
  BadMultipleMixConstructors(this._label);
  BadMultipleMixConstructors.withDefault() : _label = 'Hello';
}

class GoodFormals {
  var _label; // OK
  GoodFormals(this._label);
  GoodFormals.empty();
}

class GoodInitializer {
  var _label; // OK
  GoodInitializer() : _label = 'Hello';
  GoodInitializer.empty();
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

class F {
  var _array = new List<int>(5); // LINT

  void foo() {
    _array[0] = 3;
  }
}

// https://github.com/dart-lang/linter/issues/686
class IdBug686 {
  static int _id = 0;
  static String generateId({prefix: String}) {
    return (prefix ?? "id") + "-" + (_id++).toString() + "-" + _foo();
  }

  static String _foo() => '';
}

// analyzer's `FieldMember` vs `FieldElement` caused
// https://github.com/dart-lang/sdk/issues/34417
abstract class GenericBase<T> {
  int _current = 0; // OK
}

class GenericSub extends GenericBase<int> {
  void test() {
    _current = 1;
  }
}
