// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_macros/src/api.dart|package:macro/macro.dart|package:macros/macros.dart,
  main.dart],
 macroInstanceIds=[
  package:macro/macro.dart/Macro4/(BoolArgument:false),
  package:macro/macro.dart/Macro4/(BoolArgument:false,named:BoolArgument:true),
  package:macro/macro.dart/Macro4/(BoolArgument:true),
  package:macro/macro.dart/Macro4/(DoubleArgument:3.14),
  package:macro/macro.dart/Macro4/(DoubleArgument:3.14,named:DoubleArgument:1.41),
  package:macro/macro.dart/Macro4/(IntArgument:42),
  package:macro/macro.dart/Macro4/(IntArgument:87,named:IntArgument:42),
  package:macro/macro.dart/Macro4/(NullArgument:null),
  package:macro/macro.dart/Macro4/(NullArgument:null,named:NullArgument:null),
  package:macro/macro.dart/Macro4/(StringArgument:bar,named:StringArgument:baz),
  package:macro/macro.dart/Macro4/(StringArgument:foo),
  package:macro/macro.dart/Macro4/(StringArgument:foobar),
  package:macro/macro.dart/Macro4/(StringArgument:foobar,named:StringArgument:boz_qux),
  package:macro/macro.dart/Macro4/(StringArgument:qux,named:StringArgument:boz)],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)|Macro4(new)]
*/

import 'package:macro/macro.dart';

/*member: function1:appliedMacros=[
  Macro4.new(NullArgument:null),
  Macro4.new(NullArgument:null,named:NullArgument:null)]*/
@Macro4(null)
@Macro4(null, named: null)
function1() {}

/*member: function2:appliedMacros=[
  Macro4.new(IntArgument:42),
  Macro4.new(IntArgument:87,named:IntArgument:42)]*/
@Macro4(42)
@Macro4(87, named: 42)
function2() {}

/*member: function3:appliedMacros=[
  Macro4.new(BoolArgument:false,named:BoolArgument:true),
  Macro4.new(BoolArgument:true)]*/
@Macro4(true)
@Macro4(false, named: true)
function3() {}

/*member: function4:appliedMacros=[Macro4.new(BoolArgument:false)]*/
@Macro4(false)
function4() {}

/*member: function5:appliedMacros=[
  Macro4.new(StringArgument:bar,named:StringArgument:baz),
  Macro4.new(StringArgument:foo),
  Macro4.new(StringArgument:qux,named:StringArgument:boz)]*/
@Macro4("foo")
@Macro4("bar", named: "baz")
@Macro4(named: "boz", "qux")
function5() {}

/*member: function6:appliedMacros=[
  Macro4.new(DoubleArgument:3.14),
  Macro4.new(DoubleArgument:3.14,named:DoubleArgument:1.41)]*/
@Macro4(3.14)
@Macro4(3.14, named: 1.41)
function6() {}

/*member: function7:appliedMacros=[
  Macro4.new(StringArgument:foobar),
  Macro4.new(StringArgument:foobar,named:StringArgument:boz_qux)]*/
@Macro4("foo" "bar")
@Macro4("foo" "bar", named: "boz" "_" "qux")
function7() {}

main() {}
