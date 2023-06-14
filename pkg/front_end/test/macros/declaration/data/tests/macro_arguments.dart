// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_fe_analyzer_shared/src/macros/api.dart|package:macro/macro.dart,
  main.dart],
 macroInstanceIds=[
  package:macro/macro.dart/Macro4/(3.14),
  package:macro/macro.dart/Macro4/(3.14,named:1.41),
  package:macro/macro.dart/Macro4/(42),
  package:macro/macro.dart/Macro4/(87,named:42),
  package:macro/macro.dart/Macro4/(bar,named:baz),
  package:macro/macro.dart/Macro4/(false),
  package:macro/macro.dart/Macro4/(false,named:true),
  package:macro/macro.dart/Macro4/(foo),
  package:macro/macro.dart/Macro4/(foobar),
  package:macro/macro.dart/Macro4/(foobar,named:boz_qux),
  package:macro/macro.dart/Macro4/(null),
  package:macro/macro.dart/Macro4/(null,named:null),
  package:macro/macro.dart/Macro4/(qux,named:boz),
  package:macro/macro.dart/Macro4/(true)],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)|Macro4(new)]
*/

import 'package:macro/macro.dart';

/*member: function1:appliedMacros=[
  Macro4.new(null),
  Macro4.new(null,named:null)]*/
@Macro4(null)
@Macro4(null, named: null)
function1() {}

/*member: function2:appliedMacros=[
  Macro4.new(42),
  Macro4.new(87,named:42)]*/
@Macro4(42)
@Macro4(87, named: 42)
function2() {}

/*member: function3:appliedMacros=[
  Macro4.new(false,named:true),
  Macro4.new(true)]*/
@Macro4(true)
@Macro4(false, named: true)
function3() {}

/*member: function4:appliedMacros=[Macro4.new(false)]*/
@Macro4(false)
function4() {}

/*member: function5:appliedMacros=[
  Macro4.new(bar,named:baz),
  Macro4.new(foo),
  Macro4.new(qux,named:boz)]*/
@Macro4("foo")
@Macro4("bar", named: "baz")
@Macro4(named: "boz", "qux")
function5() {}

/*member: function6:appliedMacros=[
  Macro4.new(3.14),
  Macro4.new(3.14,named:1.41)]*/
@Macro4(3.14)
@Macro4(3.14, named: 1.41)
function6() {}

/*member: function7:appliedMacros=[
  Macro4.new(foobar),
  Macro4.new(foobar,named:boz_qux)]*/
@Macro4("foo" "bar")
@Macro4("foo" "bar", named: "boz" "_" "qux")
function7() {}

main() {}
