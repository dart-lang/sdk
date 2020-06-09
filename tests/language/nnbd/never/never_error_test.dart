// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

/// Test that `Never` has all members, and that as a result no extensions
/// apply to it.  Also test that `Never` is inferred as the type of a
/// throw expression, and as the return type of function literals that
/// never return.

import 'package:expect/expect.dart';

/// A call of the form staticErrorIfNotNever(t) will produce a static error
/// unless `t` has type `Never`.
void staticErrorIfNotNever<T extends Never>(T t) {}

void neverHasAllMembers(Never x) {
  {
    // getters
    var t = x.arglebargle;
    staticErrorIfNotNever(t);
  }
  {
    // setter
    x.arglebargle = 3;
  }
  {
    // operator[]
    x[0] = 3;
  }
  {
    // methods
    var t = x.arglebargle(0);
    staticErrorIfNotNever(t);
  }
  {
    // methods with named parameters
    var t = x.arglebargle(foo: 0);
    staticErrorIfNotNever(t);
  }
  {
    // call method
    var t = x(3);
    staticErrorIfNotNever(t);
  }
  {
    // Object members
    staticErrorIfNotNever(x.toString());
    staticErrorIfNotNever(x.toString);
    staticErrorIfNotNever(x.runtimeType);
    staticErrorIfNotNever(x.noSuchMethod);
    staticErrorIfNotNever(x.noSuchMethod(x));
    staticErrorIfNotNever(x.hashCode);
    staticErrorIfNotNever(x == x);
    staticErrorIfNotNever(x == 3);
    staticErrorIfNotNever(3 == x);
//  ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'bool' doesn't conform to the bound 'Never' of the type variable 'T' on 'staticErrorIfNotNever'.
  }
}

extension NeverExt on Never {
  int neverMethod() => 3;
}

extension ObjectExt on Object {
  int objectMethod() => 3;
}

void extensionsDontApply(Never x) {
  {
    var t = x.neverMethod();
    staticErrorIfNotNever(t);
  }
  {
    var t = x.objectMethod();
    staticErrorIfNotNever(t);
  }
  {
    var t = NeverExt(x).neverMethod();
    staticErrorIfNotNever(t);
//  ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'Never' of the type variable 'T' on 'staticErrorIfNotNever'.
  }
  {
    var t = ObjectExt(x).objectMethod();
    staticErrorIfNotNever(t);
//  ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Inferred type argument 'int' doesn't conform to the bound 'Never' of the type variable 'T' on 'staticErrorIfNotNever'.
  }
}

void throwHasTypeNever() {
  var t = throw "hello";
  staticErrorIfNotNever(t);
}

void neverReturns(bool b) {
  {
    var f = () => throw "Unreachable";
    var t = f();
    staticErrorIfNotNever(t);
  }
  {
    var f = () {
      if (b) {
        throw "argle";
      } else {
        throw "bargle";
      }
    };
    var t = f();
    staticErrorIfNotNever(t);
  }
}

void main() {
  neverHasAllMembers(throw "Unreachable");
  extensionsDontApply(throw "Unreachable");
  throwHasTypeNever();
  neverReturns(true);
}
