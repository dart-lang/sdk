// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_fe_analyzer_shared/src/macros/api.dart|package:macro/macro.dart,
  main.dart],
 macroClassIds=[
  package:macro/macro.dart/Macro1,
  package:macro/macro.dart/Macro2,
  package:macro/macro.dart/Macro3],
 macroInstanceIds=[
  package:macro/macro.dart/Macro1/(),
  package:macro/macro.dart/Macro1/(),
  package:macro/macro.dart/Macro1/(),
  package:macro/macro.dart/Macro2/(),
  package:macro/macro.dart/Macro2/(),
  package:macro/macro.dart/Macro3/(),
  package:macro/macro.dart/Macro3/()],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)]
*/
library use_macro_package;

import 'package:macro/macro.dart';

/*member: main:appliedMacros=[Macro1.new]*/
@Macro1()
void main() {}

/*class: Class1:
 appliedMacros=[Macro2.new],
 macrosAreApplied
*/
@Macro2()
class Class1 {
  /*member: Class1.:appliedMacros=[Macro3.new]*/
  @Macro3()
  Class1();

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
  /*member: Class3.field:appliedMacros=[Macro3.new]*/
  @Macro3()
  var field;
}

class Class4 {
  @NonMacro()
  var field;
}

/*member: field:appliedMacros=[Macro1.new]*/
@Macro1()
var field;

extension Extension on int {
  /*member: Extension|field:*/
  @Macro1()
  static var field;

  /*member: Extension|method:*/
  @Macro2()
  void method() {}

  /*member: Extension|staticMethod:*/
  @Macro3()
  static void staticMethod() {}
}
