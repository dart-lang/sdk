// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators.

// SharedOptions=--enable-experiment=dot-shorthands

import '../enum_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.regular(ConstructorClass ctor)
    : assert(const .constRegular(1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstConstructorAssert.named(ConstructorClass ctor)
    : assert(const .constNamed(x: 1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstConstructorAssert.optional(ConstructorClass ctor)
    : assert(const .constOptional(1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstConstructorAssert.regularExt(ConstructorExt ctor)
    : assert(const .constRegular(1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstConstructorAssert.namedExt(ConstructorExt ctor)
    : assert(const .constNamed(x: 1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstConstructorAssert.optionalExt(ConstructorExt ctor)
    : assert(const .constOptional(1) == ctor);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void notSymmetrical(ConstructorClass ctor, ConstructorExt ctorExt) {
  const ConstructorClass constCtor = .constRegular(1);
  const bool symEqRegular = .constRegular(1) == constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symEqNamed = .constNamed(x: 1) == constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symEqOptional = .constOptional(1) == constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symNeqRegular = .constRegular(1) != constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symNeqNamed = .constNamed(x: 1) != constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symNeqOptional = .constOptional(1) != constCtor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstructorExt constCtorExt = .constRegular(1);
  const bool symExtEqRegular = .constRegular(1) == constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symExtEqNamed = .constNamed(x: 1) == constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symExtEqOptional = .constOptional(1) == constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symExtNeqRegular = .constRegular(1) != constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symExtNeqNamed = .constNamed(x: 1) != constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symExtNeqOptional = .constOptional(1) != constCtorExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.new(1) == ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.regular(1) == ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.named(x: 1) == ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.optional(1) == ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.new(1) != ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.regular(1) != ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.named(x: 1) != ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.optional(1) != ctor) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.new(1) == ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.regular(1) == ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.named(x: 1) == ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.optional(1) == ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.new(1) != ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.regular(1) != ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.named(x: 1) != ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.optional(1) != ctorExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void rhsNeedsToBeShorthand(
  ConstructorClass ctor,
  ConstructorExt ctorExt,
  bool condition,
) {
  const Object obj = true;
  const bool constCondition = obj as bool;

  const constCtor = .constRegular(1);
  const bool rhsCtorEq = constCtor == (constCondition ? .constRegular(1) : ConstructorClass.constNamed(x: 1));
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsCtorNeq = constCtor != (constCondition ? ConstructorClass.constOptional(1) : .constRegular(1));
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (ctor == (condition ? .new(1) : .regular(1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor != (condition ? .optional(1) : .named(x: 1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor case == (constCondition ? const .constRegular(1) : const .constNamed(x: 1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctor case != (constCondition ? const .constOptional(1) : const .constRegular(1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  const constCtorExt = .constRegular(1);
  const bool rhsCtorExtEq = constCtorExt == (constCondition ? .constRegular(1) : ConstructorExt.constNamed(x: 1));
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsCtorExtNeq = constCtorExt != (constCondition ? ConstructorExt.constOptional(1) : .constRegular(1));
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (ctorExt == (condition ? .new(1) : .regular(1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctorExt != (condition ? .named(x: 1) : .optional(1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctorExt case == (constCondition ? const .constRegular(1) : const .constNamed(x: 1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (ctorExt case != (constCondition ? const .constOptional(1) : const .constRegular(1))) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
}

void objectContextType(ConstructorClass ctor, ConstructorExt ctorExt) {
  const ConstructorClass constCtor = .constRegular(1);
  const bool contextTypeCtorEqRegular = (constCtor as Object) == .constRegular(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorEqNamed = (constCtor as Object) == .constNamed(x: 1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorEqOptional = (constCtor as Object) == .constOptional(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorNeqRegular = (constCtor as Object) != .constRegular(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorNeqNamed = (constCtor as Object) != .constNamed(x: 1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorNeqOptional = (constCtor as Object) != .constOptional(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .new(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .regular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .named(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) == .optional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .new(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .regular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .named(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) != .optional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case == const .constRegular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case == const .constNamed(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case == const .constOptional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case != const .constRegular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case != const .constNamed(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctor as Object) case != const .constOptional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const ConstructorExt constCtorExt = .constRegular(1);
  const bool contextTypeCtorExtEqRegular = (constCtorExt as Object) == .constRegular(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorExtEqNamed = (constCtorExt as Object) == .constNamed(x: 1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorExtEqOptional = (constCtorExt as Object) == .constOptional(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorExtNeqRegular = (constCtorExt as Object) != .constRegular(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorExtNeqNamed = (constCtorExt as Object) != .constNamed(x: 1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeCtorExtNeqOptional = (constCtorExt as Object) != .constOptional(1);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) == .new(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) == .regular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) == .named(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) == .optional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) != .new(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) != .regular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) != .named(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) != .optional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case == const .constRegular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case == const .constNamed(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case == const .constOptional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case != const .constRegular(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case != const .constNamed(x: 1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((ctorExt as Object) case != const .constOptional(1)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void main() {
  ConstructorClass ctor = .new(1);
  const ConstructorClass constCtor = .constRegular(1);
  ConstructorExt ctorExt = .new(1);
  const ConstructorExt constCtorExt = .constRegular(1);

  notSymmetrical(ctor, ctorExt);
  rhsNeedsToBeShorthand(ctor, ctorExt, true);
  rhsNeedsToBeShorthand(ctor, ctorExt, false);
  objectContextType(ctor, ctorExt);

  // Test the constant evaluation for enum shorthands in const constructor
  // asserts.
  const ConstConstructorAssert.regular(constCtor);
  const ConstConstructorAssert.named(constCtor);
  const ConstConstructorAssert.optional(constCtor);
  const ConstConstructorAssert.regularExt(constCtorExt);
  const ConstConstructorAssert.namedExt(constCtorExt);
  const ConstConstructorAssert.optionalExt(constCtorExt);
}
