// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:macro/macro.dart,
  main.dart],
 macroClassIds=[
  package:macro/macro.dart/Macro1,
  package:precompiled_macro/precompiled_macro.dart/PrecompiledMacro],
 macroInstanceIds=[
  package:macro/macro.dart/Macro1/(),
  package:precompiled_macro/precompiled_macro.dart/PrecompiledMacro/()],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[package:macro/macro.dart=Macro1(named/new)|Macro2(named/new)|Macro3(named/new)]
*/

import 'package:precompiled_macro/precompiled_macro.dart';
import 'package:macro/macro.dart';

/*member: main:appliedMacros=[
  Macro1.new,
  PrecompiledMacro.new]*/
@PrecompiledMacro()
@Macro1()
void main() {}
