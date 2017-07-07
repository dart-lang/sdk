// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that various type errors doesn't invoke user-defined code
// during error reporting.

class MyClass {}

class IntTypeError {
  toString() {
    int value = wrap(this);
    return super.toString();
  }
}

class StringTypeError {
  toString() {
    String value = wrap(this);
    return super.toString();
  }
}

class DoubleTypeError {
  toString() {
    double value = wrap(this);
    return super.toString();
  }
}

class NumTypeError {
  toString() {
    num value = wrap(this);
    return super.toString();
  }
}

class BoolTypeError {
  toString() {
    bool value = wrap(this);
    return super.toString();
  }
}

class FunctionTypeError {
  toString() {
    Function value = wrap(this);
    return super.toString();
  }
}

class MyClassTypeError {
  toString() {
    MyClass value = wrap(this);
    return super.toString();
  }
}

class ListTypeError {
  toString() {
    List value = wrap(this);
    return super.toString();
  }
}

class IntCastError {
  toString() {
    wrap(this) as int;
    return super.toString();
  }
}

class StringCastError {
  toString() {
    wrap(this) as String;
    return super.toString();
  }
}

class DoubleCastError {
  toString() {
    wrap(this) as double;
    return super.toString();
  }
}

class NumCastError {
  toString() {
    wrap(this) as num;
    return super.toString();
  }
}

class BoolCastError {
  toString() {
    wrap(this) as bool;
    return super.toString();
  }
}

class FunctionCastError {
  toString() {
    wrap(this) as Function;
    return super.toString();
  }
}

class MyClassCastError {
  toString() {
    wrap(this) as MyClass;
    return super.toString();
  }
}

class ListCastError {
  toString() {
    wrap(this) as List;
    return super.toString();
  }
}

/// Defeat optimizations of type checks.
wrap(e) {
  if (new DateTime.now().year == 1980) return null;
  return e;
}

checkTypeError(o) {
  try {
    print(o);
  } on TypeError catch (e) {
    print(e); // This might provoke an error.
    if (typeAssertionsEnabled) return; // Expected type error.
    rethrow; // Rethrow unexpected type error.
  }
  if (typeAssertionsEnabled) {
    throw 'expected TypeError';
  }
}

checkAssert(o) {
  try {
    assert(o);
  } on TypeError catch (e) {
    print(e); // This might provoke an error.
    if (!assertStatementsEnabled) rethrow; // Unexpected error.
  }
}

checkCastError(o) {
  try {
    print(o);
  } on TypeError catch (e) {
    print('unexpected type error: ${Error.safeToString(e)}');
    rethrow; // Unexpected type error.
  } on CastError catch (e) {
    print(e); // This might provoke an error.
    return; // Expected a cast error.
  }
  throw 'expected CastError';
}

main() {
  checkTypeError(new IntTypeError());
  checkTypeError(new StringTypeError());
  checkTypeError(new DoubleTypeError());
  checkTypeError(new NumTypeError());
  checkTypeError(new BoolTypeError());
  checkTypeError(new FunctionTypeError());
  checkTypeError(new MyClassTypeError());
  checkTypeError(new ListTypeError());

  checkAssert(new IntTypeError());
  checkAssert(new StringTypeError());
  checkAssert(new DoubleTypeError());
  checkAssert(new NumTypeError());
  checkAssert(new BoolTypeError());
  checkAssert(new FunctionTypeError());
  checkAssert(new MyClassTypeError());
  checkAssert(new ListTypeError());

  checkCastError(new IntCastError());
  checkCastError(new StringCastError());
  checkCastError(new DoubleCastError());
  checkCastError(new NumCastError());
  checkCastError(new BoolCastError());
  checkCastError(new FunctionCastError());
  checkCastError(new MyClassCastError());
  checkCastError(new ListCastError());
}
