// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Class {
  int property = 0;
  int method() => 0;
  Function functionField = () {};
  void Function() functionTypeField = () {};
  Function get functionGetter => () {};
  void Function() get functionTypeGetter => () {};
}

Function? get nullableFunction => () {};

void Function()? get nullableFunctionType => () {};

int? get nullableInt => 0;

Map<dynamic, dynamic>? get nullableMap => {};

Class? get nullableClass => new Class();

var topLevelBinary = nullableInt + 0;
var topLevelUnary = -nullableInt;
var topLevelIndexGet = nullableMap[0];
var topLevelIndexSet = nullableMap[0] = 1;
var topLevelIndexGetSet = nullableMap[0] += 1;
var topLevelPropertyGet = nullableClass.property;
var topLevelPropertySet = nullableClass.property = 1;
var topLevelPropertyGetSet = nullableClass.property += 1;
var topLevelMethodInvocation = nullableClass.method();
var topLevelMethodTearOff = nullableClass.method;
var topLevelFunctionImplicitCall = nullableFunction();
var topLevelFunctionExplicitCall = nullableFunction.call();
var topLevelFunctionTearOff = nullableFunction.call;
var topLevelFunctionTypeImplicitCall = nullableFunctionType();
var topLevelFunctionTypeExplicitCall = nullableFunctionType.call();
var topLevelFunctionTypeTearOff = nullableFunctionType.call;
var topLevelFunctionField = nullableClass.functionField();
var topLevelFunctionTypeField = nullableClass.functionTypeField();
var topLevelFunctionGetter = nullableClass.functionGetter();
var topLevelFunctionTypeGetter = nullableClass.functionTypeGetter();

test() {
  var localBinary = nullableInt + 0;
  var localUnary = -nullableInt;
  var localIndexGet = nullableMap[0];
  var localIndexSet = nullableMap[0] = 1;
  var localIndexGetSet = nullableMap[0] += 1;
  var localPropertyGet = nullableClass.property;
  var localPropertySet = nullableClass.property = 1;
  var localPropertyGetSet = nullableClass.property += 1;
  var localMethodInvocation = nullableClass.method();
  var localMethodTearOff = nullableClass.method;
  var localFunctionImplicitCall = nullableFunction();
  var localFunctionExplicitCall = nullableFunction.call();
  var localFunctionTearOff = nullableFunction.call;
  var localFunctionTypeImplicitCall = nullableFunctionType();
  var localFunctionTypeExplicitCall = nullableFunctionType.call();
  var localFunctionTypeTearOff = nullableFunctionType.call;
  var localFunctionField = nullableClass.functionField();
  var localFunctionTypeField = nullableClass.functionTypeField();
  var localFunctionGetter = nullableClass.functionGetter();
  var localFunctionTypeGetter = nullableClass.functionTypeGetter();
}

main() {}
