// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Tearoffable {
  void call() {}
}

ok<
        XnonNull extends Object,
        YnonNull extends XnonNull,
        XpotentiallyNull extends Object?,
        YpotentiallyNull extends XpotentiallyNull>(
    dynamic dynamicArg,
    Object objectArg,
    num numArg,
    int intArg,
    double doubleArg,
    Function functionArg,
    void Function() toVoidArg,
    Tearoffable tearoffableArg,
    XnonNull xNonNullArg,
    XpotentiallyNull xPotentiallyNullArg,
    YnonNull yNonNullArg,
    YpotentiallyNull yPotentiallyNullArg) {
  dynamic dynamicVar = dynamicArg;
  dynamicVar = objectArg;
  dynamicVar = numArg;
  dynamicVar = intArg;
  dynamicVar = doubleArg;
  dynamicVar = functionArg;
  dynamicVar = toVoidArg;
  dynamicVar = tearoffableArg;
  dynamicVar = xNonNullArg;
  dynamicVar = xPotentiallyNullArg;
  dynamicVar = yNonNullArg;
  dynamicVar = yPotentiallyNullArg;

  Object objectVar = dynamicArg;
  objectVar = objectArg;
  objectVar = numArg;
  objectVar = intArg;
  objectVar = functionArg;
  objectVar = toVoidArg;
  objectVar = tearoffableArg;
  objectVar = xNonNullArg;
  objectVar = yNonNullArg;

  num numVar = dynamicArg;
  numVar = numArg;
  numVar = intArg;
  numVar = doubleArg;

  int intVar = dynamicArg;
  intVar = intArg;

  double doubleVar = dynamicArg;
  doubleVar = doubleArg;

  Function functionVar = dynamicArg;
  functionVar = functionArg;
  functionVar = toVoidArg;
  functionVar = tearoffableArg;

  void Function() toVoidVar = dynamicArg;
  toVoidVar = toVoidArg;
  toVoidVar = tearoffableArg;

  Tearoffable tearoffableVar = dynamicArg;
  tearoffableVar = tearoffableArg;

  XnonNull xNonNullVar = dynamicArg;
  xNonNullVar = xNonNullArg;
  xNonNullVar = yNonNullArg;

  YnonNull yNonNullVar = dynamicArg;
  yNonNullVar = yNonNullArg;

  XpotentiallyNull xPotentiallyNullVar = dynamicArg;
  xPotentiallyNullVar = xPotentiallyNullArg;
  xPotentiallyNullVar = yPotentiallyNullArg;

  YpotentiallyNull yPotentiallyNullVar = dynamicArg;
  yPotentiallyNullVar = yPotentiallyNullArg;
}

error<
        XnonNull extends Object,
        YnonNull extends XnonNull,
        XpotentiallyNull extends Object?,
        YpotentiallyNull extends XpotentiallyNull>(
    Object objectArg,
    Object? objectNullableArg,
    num numArg,
    num? numNullableArg,
    int intArg,
    int? intNullableArg,
    double doubleArg,
    double? doubleNullableArg,
    Function functionArg,
    Function? functionNullableArg,
    void Function() toVoidArg,
    void Function()? toVoidNullableArg,
    Tearoffable tearoffableArg,
    Tearoffable? tearoffableNullableArg,
    XnonNull xNonNullArg,
    XnonNull? xNonNullNullableArg,
    XpotentiallyNull xPotentiallyNullArg,
    XpotentiallyNull? xPotentiallyNullNullableArg,
    YnonNull yNonNullArg,
    YnonNull? yNonNullNullableArg,
    YpotentiallyNull yPotentiallyNullArg,
    YpotentiallyNull? yPotentiallyNullNullableArg) {
  Object objectVar = objectNullableArg;
  objectVar = numNullableArg;
  objectVar = intNullableArg;
  objectVar = doubleNullableArg;
  objectVar = functionNullableArg;
  objectVar = toVoidNullableArg;
  objectVar = tearoffableNullableArg;
  objectVar = xNonNullNullableArg;
  objectVar = xPotentiallyNullArg;
  objectVar = xPotentiallyNullNullableArg;
  objectVar = yNonNullNullableArg;
  objectVar = yPotentiallyNullArg;
  objectVar = yPotentiallyNullNullableArg;

  num numVar = objectArg;
  numVar = objectNullableArg;
  numVar = numNullableArg;
  numVar = intNullableArg;
  numVar = doubleNullableArg;
  numVar = functionArg;
  numVar = functionNullableArg;
  numVar = toVoidArg;
  numVar = toVoidNullableArg;
  numVar = tearoffableArg;
  numVar = tearoffableNullableArg;
  numVar = xNonNullArg;
  numVar = xNonNullNullableArg;
  numVar = xPotentiallyNullArg;
  numVar = xPotentiallyNullNullableArg;
  numVar = yNonNullArg;
  numVar = yNonNullNullableArg;
  numVar = yPotentiallyNullArg;
  numVar = yPotentiallyNullNullableArg;

  int intVar = objectArg;
  intVar = objectNullableArg;
  intVar = numArg;
  intVar = numNullableArg;
  intVar = intNullableArg;
  intVar = doubleArg;
  intVar = doubleNullableArg;
  intVar = functionArg;
  intVar = functionNullableArg;
  intVar = toVoidArg;
  intVar = toVoidNullableArg;
  intVar = tearoffableArg;
  intVar = tearoffableNullableArg;
  intVar = xNonNullArg;
  intVar = xNonNullNullableArg;
  intVar = xPotentiallyNullArg;
  intVar = xPotentiallyNullNullableArg;
  intVar = yNonNullArg;
  intVar = yNonNullNullableArg;
  intVar = yPotentiallyNullArg;
  intVar = yPotentiallyNullNullableArg;

  double doubleVar = objectArg;
  doubleVar = objectNullableArg;
  doubleVar = numArg;
  doubleVar = numNullableArg;
  doubleVar = intArg;
  doubleVar = intNullableArg;
  doubleVar = doubleNullableArg;
  doubleVar = functionArg;
  doubleVar = functionNullableArg;
  doubleVar = toVoidArg;
  doubleVar = toVoidNullableArg;
  doubleVar = tearoffableArg;
  doubleVar = tearoffableNullableArg;
  doubleVar = xNonNullArg;
  doubleVar = xNonNullNullableArg;
  doubleVar = xPotentiallyNullArg;
  doubleVar = xPotentiallyNullNullableArg;
  doubleVar = yNonNullArg;
  doubleVar = yNonNullNullableArg;
  doubleVar = yPotentiallyNullArg;
  doubleVar = yPotentiallyNullNullableArg;

  Function functionVar = objectArg;
  functionVar = objectNullableArg;
  functionVar = numArg;
  functionVar = numNullableArg;
  functionVar = intArg;
  functionVar = intNullableArg;
  functionVar = doubleArg;
  functionVar = doubleNullableArg;
  functionVar = functionNullableArg;
  functionVar = toVoidNullableArg;
  functionVar = tearoffableNullableArg;
  functionVar = xNonNullArg;
  functionVar = xNonNullNullableArg;
  functionVar = xPotentiallyNullArg;
  functionVar = xPotentiallyNullNullableArg;
  functionVar = yNonNullArg;
  functionVar = yNonNullNullableArg;
  functionVar = yPotentiallyNullArg;
  functionVar = yPotentiallyNullNullableArg;

  void Function() toVoidVar = objectArg;
  toVoidVar = objectNullableArg;
  toVoidVar = numArg;
  toVoidVar = numNullableArg;
  toVoidVar = intArg;
  toVoidVar = intNullableArg;
  toVoidVar = doubleArg;
  toVoidVar = doubleNullableArg;
  toVoidVar = functionArg;
  toVoidVar = functionNullableArg;
  toVoidVar = toVoidNullableArg;
  toVoidVar = tearoffableNullableArg;
  toVoidVar = xNonNullArg;
  toVoidVar = xNonNullNullableArg;
  toVoidVar = xPotentiallyNullArg;
  toVoidVar = xPotentiallyNullNullableArg;
  toVoidVar = yNonNullArg;
  toVoidVar = yNonNullNullableArg;
  toVoidVar = yPotentiallyNullArg;
  toVoidVar = yPotentiallyNullNullableArg;

  Tearoffable tearoffableVar = objectArg;
  tearoffableVar = objectNullableArg;
  tearoffableVar = numArg;
  tearoffableVar = numNullableArg;
  tearoffableVar = intArg;
  tearoffableVar = intNullableArg;
  tearoffableVar = doubleArg;
  tearoffableVar = doubleNullableArg;
  tearoffableVar = functionArg;
  tearoffableVar = functionNullableArg;
  tearoffableVar = toVoidArg;
  tearoffableVar = toVoidNullableArg;
  tearoffableVar = tearoffableNullableArg;
  tearoffableVar = xNonNullArg;
  tearoffableVar = xNonNullNullableArg;
  tearoffableVar = xPotentiallyNullArg;
  tearoffableVar = xPotentiallyNullNullableArg;
  tearoffableVar = yNonNullArg;
  tearoffableVar = yNonNullNullableArg;
  tearoffableVar = yPotentiallyNullArg;
  tearoffableVar = yPotentiallyNullNullableArg;

  XnonNull xNonNullVar = objectArg;
  xNonNullVar = objectNullableArg;
  xNonNullVar = numArg;
  xNonNullVar = numNullableArg;
  xNonNullVar = intArg;
  xNonNullVar = intNullableArg;
  xNonNullVar = doubleArg;
  xNonNullVar = doubleNullableArg;
  xNonNullVar = functionArg;
  xNonNullVar = functionNullableArg;
  xNonNullVar = toVoidArg;
  xNonNullVar = toVoidNullableArg;
  xNonNullVar = tearoffableArg;
  xNonNullVar = tearoffableNullableArg;
  xNonNullVar = xNonNullNullableArg;
  xNonNullVar = xPotentiallyNullArg;
  xNonNullVar = xPotentiallyNullNullableArg;
  xNonNullVar = yNonNullNullableArg;
  xNonNullVar = yPotentiallyNullArg;
  xNonNullVar = yPotentiallyNullNullableArg;

  XpotentiallyNull xPotentiallyNullVar = objectArg;
  xPotentiallyNullVar = objectNullableArg;
  xPotentiallyNullVar = numArg;
  xPotentiallyNullVar = numNullableArg;
  xPotentiallyNullVar = intArg;
  xPotentiallyNullVar = intNullableArg;
  xPotentiallyNullVar = doubleArg;
  xPotentiallyNullVar = doubleNullableArg;
  xPotentiallyNullVar = functionArg;
  xPotentiallyNullVar = functionNullableArg;
  xPotentiallyNullVar = toVoidArg;
  xPotentiallyNullVar = toVoidNullableArg;
  xPotentiallyNullVar = tearoffableArg;
  xPotentiallyNullVar = tearoffableNullableArg;
  xPotentiallyNullVar = xNonNullArg;
  xPotentiallyNullVar = xNonNullNullableArg;
  xPotentiallyNullVar = xPotentiallyNullNullableArg;
  xPotentiallyNullVar = yNonNullArg;
  xPotentiallyNullVar = yNonNullNullableArg;
  xPotentiallyNullVar = yPotentiallyNullNullableArg;

  YnonNull yNonNullVar = objectArg;
  yNonNullVar = objectNullableArg;
  yNonNullVar = numArg;
  yNonNullVar = numNullableArg;
  yNonNullVar = intArg;
  yNonNullVar = intNullableArg;
  yNonNullVar = doubleArg;
  yNonNullVar = doubleNullableArg;
  yNonNullVar = functionArg;
  yNonNullVar = functionNullableArg;
  yNonNullVar = toVoidArg;
  yNonNullVar = toVoidNullableArg;
  yNonNullVar = tearoffableArg;
  yNonNullVar = tearoffableNullableArg;
  yNonNullVar = xNonNullArg;
  yNonNullVar = xNonNullNullableArg;
  yNonNullVar = xPotentiallyNullArg;
  yNonNullVar = xPotentiallyNullNullableArg;
  yNonNullVar = yNonNullNullableArg;
  yNonNullVar = yPotentiallyNullArg;
  yNonNullVar = yPotentiallyNullNullableArg;

  YpotentiallyNull yPotentiallyNullVar = objectArg;
  yPotentiallyNullVar = objectNullableArg;
  yPotentiallyNullVar = numArg;
  yPotentiallyNullVar = numNullableArg;
  yPotentiallyNullVar = intArg;
  yPotentiallyNullVar = intNullableArg;
  yPotentiallyNullVar = doubleArg;
  yPotentiallyNullVar = doubleNullableArg;
  yPotentiallyNullVar = functionArg;
  yPotentiallyNullVar = functionNullableArg;
  yPotentiallyNullVar = toVoidArg;
  yPotentiallyNullVar = toVoidNullableArg;
  yPotentiallyNullVar = tearoffableArg;
  yPotentiallyNullVar = tearoffableNullableArg;
  yPotentiallyNullVar = xNonNullArg;
  yPotentiallyNullVar = xNonNullNullableArg;
  yPotentiallyNullVar = xPotentiallyNullArg;
  yPotentiallyNullVar = xPotentiallyNullNullableArg;
  yPotentiallyNullVar = yNonNullArg;
  yPotentiallyNullVar = yNonNullNullableArg;
  yPotentiallyNullVar = yPotentiallyNullNullableArg;
}

main() {}
