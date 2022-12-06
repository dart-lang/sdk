// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N no_leading_underscores_for_local_identifiers`

/// https://github.com/dart-lang/linter/issues/3360
int _g() { // OK (not local)
  int _bar() { // LINT
    return 10;
  }
  var x = () {
    _foo() { }; // LINT
  };
  return _bar();
}

class _A { // OK
  int _a() { // OK
    int _bar() => 10; // LINT
    return _bar();
  }
}

///https://github.com/dart-lang/linter/issues/3126
void fn0() {
  for (var _ in []) { } // OK
  var _ = g(); //OK
  for (var __ = 0; __ < 1; ++__) { } // OK
}

int g() => 0;

/// https://github.com/dart-lang/linter/issues/3127
class P {
  final int _p;
  const P([this._p = 7]); // OK
}

var _foo = 0; // OK
const _foo1 = 1; // OK
final _foo2 = 2; // OK

void fn() {
  try {
  } catch(_) { } // OK
  var _f1, // LINT
      _f2; // LINT
  const _foo1 = 1; // LINT
  final _foo2 = 2; // LINT
  var foo_value = 0; // OK
  var foo__value = 0; // OK
  var foo__value_ = 0; // OK
  () {
    var _f = 0; // LINT
  }();
}

void fn2(_param1) => null; // LINT

void fn3(param) => null; // OK

void fn4(_) => null; // OK

void fn5(param_value) => null; // OK

void fn6(void Function() function) {
  fn6(() {
    var _v = 1; // LINT
  });
}

class TestClass {
  var _foo = 0; // OK
  static const _foo1 = 1; // OK
  final _foo2 = 2; // OK

  void foo() {
    var _foo = 0; // LINT
    const _foo1 = 1; // LINT
    final _foo2 = 2; // LINT
    var foo_value = 0; // OK
    var foo__value = 0; // OK
    var foo__value_ = 0; // OK

    for(var _x in [1,2,3]) {} // LINT
    for(var x in [1,2,3]) {} // OK

    [1,2,3].forEach((_x) => fn()); // LINT
    [1,2,3].forEach((x) => fn()); // OK
    [1,2,3].forEach((_) => fn()); // OK

    for (var _i = 0; _i < [].length; ++_i) { } // LINT

    for (var _i = 0, // LINT
        _j = 0; // LINT
        ;
    ++_i, ++_j) {}

    try {}
    catch(_error) {} // LINT

    try {}
    catch(error) { // OK
    }

    try {}
    catch(error, _stackTrace) {} // LINT

    try {}
    catch(error, stackTrace) { // OK
    }

    for (var _e in ['']) { // LINT
    }

    void bar(var _baz) { } // LINT
  }

  void foo1(_param) {} // LINT

  void foo2(param) {} // OK

  void foo3(_) {} // OK

  void foo4(param_value) {} // OK

  void foo5(param, [_positional]) {} // LINT

  void foo6(param, [positional]) {} // OK

  // ignore: private_optional_parameter
  void foo7({required _named}) {} // OK

  // ignore: private_optional_parameter
  void foo8({_named}) {} // OK

  void foo9({named}) {} // OK

}

typedef _OutputFunction = void Function(String msg); // OK

class C {
  int _i;
  C(this._i);
}

class D extends C {
  D(super._i); // OK
}
