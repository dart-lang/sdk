// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Definition Order:
 topLevelFunction1:FunctionDefinitionMacro1.new()
 topLevelFunction2:FunctionDefinitionMacro1.new()
 topLevelFunction3:FunctionDefinitionMacro1.new()
 topLevelFunction4:FunctionDefinitionMacro1.new()
 topLevelFunction5:FunctionDefinitionMacro1.new()
 topLevelFunction6:FunctionDefinitionMacro1.new()
 topLevelFunction7:FunctionDefinitionMacro1.new()
 topLevelFunction8:FunctionDefinitionMacro1.new()
Definitions:
import 'dart:core' as prefix0;
import 'dart:math' as prefix1;

augment void topLevelFunction1() {
  throw 42;
}
augment prefix0.dynamic topLevelFunction2() {
  throw 42;
}
augment prefix0.int topLevelFunction3() {
  throw 42;
}
augment prefix0.dynamic topLevelFunction4() {
  throw 42;
}
augment prefix1.Random topLevelFunction5() {
  throw 42;
}
augment prefix0.List<prefix0.int> topLevelFunction6() {
  throw 42;
}
augment prefix0.Map<prefix1.Random, prefix0.List<prefix0.int>> topLevelFunction7() {
  throw 42;
}
augment prefix0.Map<prefix0.int?, prefix0.String>? topLevelFunction8() {
  throw 42;
}*/

import 'dart:math' as math;

import 'package:macro/macro.dart';

/*member: topLevelFunction1:
augment void topLevelFunction1() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external void topLevelFunction1();

/*member: topLevelFunction2:
augment dynamic topLevelFunction2() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external dynamic topLevelFunction2();

/*member: topLevelFunction3:
augment int topLevelFunction3() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external int topLevelFunction3();

/*member: topLevelFunction4:
augment dynamic topLevelFunction4() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external topLevelFunction4();

/*member: topLevelFunction5:
augment Random topLevelFunction5() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external math.Random topLevelFunction5();

/*member: topLevelFunction6:
augment List<int> topLevelFunction6() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external List<int> topLevelFunction6();

/*member: topLevelFunction7:
augment Map<Random, List<int>> topLevelFunction7() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external Map<math.Random, List<int>> topLevelFunction7();

/*member: topLevelFunction8:
augment Map<int?, String>? topLevelFunction8() {
  throw 42;
}*/
@FunctionDefinitionMacro1()
external Map<int?, String>? topLevelFunction8();
