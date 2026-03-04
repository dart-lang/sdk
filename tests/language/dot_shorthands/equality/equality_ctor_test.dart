// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the == and != behaviour for dot shorthands with constructors.

import '../dot_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.regular(ConstructorClass ctor)
    : assert(ctor == const .constRegular(1));

  const ConstConstructorAssert.named(ConstructorClass ctor)
    : assert(ctor == const .constNamed(x: 1));

  const ConstConstructorAssert.optional(ConstructorClass ctor)
    : assert(ctor == const .constOptional(1));

  const ConstConstructorAssert.regularExt(ConstructorExt ctor)
    : assert(ctor == const .constRegular(1));

  const ConstConstructorAssert.namedExt(ConstructorExt ctor)
    : assert(ctor == const .constNamed(x: 1));

  const ConstConstructorAssert.optionalExt(ConstructorExt ctor)
    : assert(ctor == const .constOptional(1));
}

void main() {
  ConstructorClass ctor = ConstructorClass(1);
  const ConstructorClass constCtor = .constRegular(1);

  const bool constEqRegular = constCtor == .constRegular(1);
  const bool constEqNamed = constCtor == .constNamed(x: 1);
  const bool constEqOptional = constCtor == .constOptional(1);

  const bool constNeqRegular = constCtor != .constRegular(1);
  const bool constNeqNamed = constCtor != .constNamed(x: 1);
  const bool constNeqOptional = constCtor != .constOptional(1);

  if (ctor == .new(1)) print('ok');
  if (ctor == .regular(1)) print('ok');
  if (ctor == .named(x: 1)) print('ok');
  if (ctor == .optional(1)) print('ok');

  if (ctor case == const .constRegular(1)) print('ok');
  if (ctor case == const .constNamed(x: 1)) print('ok');
  if (ctor case == const .constOptional(1)) print('ok');

  if (ctor != .new(1)) print('ok');
  if (ctor != .regular(1)) print('ok');
  if (ctor != .named(x: 1)) print('ok');
  if (ctor != .optional(1)) print('ok');

  if (ctor case != const .constRegular(1)) print('ok');
  if (ctor case != const .constNamed(x: 1)) print('ok');
  if (ctor case != const .constOptional(1)) print('ok');

  ConstructorExt ctorExt = ConstructorExt(1);
  const ConstructorExt constCtorExt = .constRegular(1);

  const bool constEqRegularExt = constCtorExt == .constRegular(1);
  const bool constEqNamedExt = constCtorExt == .constNamed(x: 1);
  const bool constEqOptionalExt = constCtorExt == .constOptional(1);

  const bool constNeqRegularExt = constCtorExt != .constRegular(1);
  const bool constNeqNamedExt = constCtorExt != .constNamed(x: 1);
  const bool constNeqOptionalExt = constCtorExt != .constOptional(1);

  if (ctorExt == .new(1)) print('ok');
  if (ctorExt == .regular(1)) print('ok');
  if (ctorExt == .named(x: 1)) print('ok');
  if (ctorExt == .optional(1)) print('ok');

  if (ctorExt case == const .constRegular(1)) print('ok');
  if (ctorExt case == const .constNamed(x: 1)) print('ok');
  if (ctorExt case == const .constOptional(1)) print('ok');

  if (ctorExt != .new(1)) print('ok');
  if (ctorExt != .regular(1)) print('ok');
  if (ctorExt != .named(x: 1)) print('ok');
  if (ctorExt != .optional(1)) print('ok');

  if (ctorExt case != const .constRegular(1)) print('ok');
  if (ctorExt case != const .constNamed(x: 1)) print('ok');
  if (ctorExt case != const .constOptional(1)) print('ok');

  // Test the constant evaluation for dot shorthands in const constructor
  // asserts.
  const ConstConstructorAssert.regular(constCtor);
  const ConstConstructorAssert.named(constCtor);
  const ConstConstructorAssert.optional(constCtor);
  const ConstConstructorAssert.regularExt(constCtorExt);
  const ConstConstructorAssert.namedExt(constCtorExt);
  const ConstConstructorAssert.optionalExt(constCtorExt);
}
