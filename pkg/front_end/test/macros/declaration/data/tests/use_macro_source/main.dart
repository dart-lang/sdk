// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  macro_lib.dart|package:_fe_analyzer_shared/src/macros/api.dart,
  main.dart],
 macroClassIds=[
  macro_lib.dart/Macro1,
  macro_lib.dart/Macro2],
 macroInstanceIds=[
  macro_lib.dart/Macro1/(),
  macro_lib.dart/Macro1/(),
  macro_lib.dart/Macro1/(),
  macro_lib.dart/Macro2/(),
  macro_lib.dart/Macro2/()],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[macro_lib.dart=Macro1(new)|Macro2(new)]
*/

import 'macro_lib.dart';

/*member: main:appliedMacros=[Macro1.new]*/
@Macro1()
void main() {}

/*class: Class1:
 appliedMacros=[Macro2.new],
 macrosAreApplied
*/
@Macro2()
class Class1 {
  /*member: Class1.method:appliedMacros=[
    Macro1.new,
    Macro2.new]*/
  @Macro1()
  @Macro2()
  void method() {}
}

@NonMacro()
class Class2 {}

/*class: Class3:macrosAreApplied*/
class Class3 {
  /*member: Class3.field:appliedMacros=[Macro1.new]*/
  @Macro1()
  var field;
}

class Class4 {
  @NonMacro()
  var field;
}
