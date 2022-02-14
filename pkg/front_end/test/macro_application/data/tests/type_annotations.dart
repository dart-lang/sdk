// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:macro/macro.dart';

/*member: topLevelFunction1:

augment void topLevelFunction1() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction1();

/*member: topLevelFunction2:

augment dynamic topLevelFunction2() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external dynamic topLevelFunction2();

/*member: topLevelFunction3:

augment int topLevelFunction3() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external int topLevelFunction3();

/*member: topLevelFunction4:

augment dynamic topLevelFunction4() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external topLevelFunction4();

/*member: topLevelFunction5:

augment math.Random topLevelFunction5() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external math.Random topLevelFunction5();

/*member: topLevelFunction6:

augment List<int> topLevelFunction6() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external List<int> topLevelFunction6();

/*member: topLevelFunction7:

augment Map<math.Random, List<int>> topLevelFunction7() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external Map<math.Random, List<int>> topLevelFunction7();

/*member: topLevelFunction8:

augment Map<int?, String>? topLevelFunction8() {
  return 42;
}*/
@FunctionDefinitionMacro1()
external Map<int?, String>? topLevelFunction8();
