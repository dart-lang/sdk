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
  package:macro/macro.dart/Macro1/named(),
  package:macro/macro.dart/Macro2/(),
  package:macro/macro.dart/Macro2/named(),
  package:macro/macro.dart/Macro2/named(),
  package:macro/macro.dart/Macro2/named(),
  package:macro/macro.dart/Macro3/(),
  package:macro/macro.dart/Macro3/(),
  package:macro/macro.dart/Macro3/(),
  package:macro/macro.dart/Macro3/named(),
  package:macro/macro.dart/Macro3/named()],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)]
*/

import 'package:macro/macro.dart';
import 'package:macro/macro.dart' as prefix;

/*class: Class:
 appliedMacros=[
  Macro1.new,
  Macro2.named,
  Macro2.new,
  Macro3.named],
 macrosAreApplied
*/
@Macro2.named()
@prefix.Macro2()
@prefix.Macro3.named()
@Macro1()
class Class {
  /*member: Class.:appliedMacros=[
    Macro1.named,
    Macro1.new,
    Macro2.named,
    Macro3.new]*/
  @Macro1.named()
  @prefix.Macro1()
  @prefix.Macro2.named()
  @Macro3()
  Class();

  /*member: Class.method:appliedMacros=[Macro3.named]*/
  @Macro3.named()
  void method() {}

  /*member: Class.field:appliedMacros=[Macro3.new]*/
  @prefix.Macro3()
  var field;
}

/*member: method:appliedMacros=[Macro2.named]*/
@Macro2.named()
void method() {}

@Macro3()
/*member: field:appliedMacros=[Macro3.new]*/
var field;

main() {}
