// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  macro_lib1.dart|macro_lib2a.dart|package:_fe_analyzer_shared/src/macros/api.dart,
  macro_lib2b.dart,
  main.dart],
 macroClassIds=[
  macro_lib1.dart/Macro1,
  macro_lib2a.dart/Macro2a,
  macro_lib2b.dart/Macro2b],
 macroInstanceIds=[
  macro_lib1.dart/Macro1/(),
  macro_lib2a.dart/Macro2a/(),
  macro_lib2a.dart/Macro2a/(),
  macro_lib2b.dart/Macro2b/()],
 macrosAreApplied,
 macrosAreAvailable,
 neededPrecompilations=[macro_lib1.dart=Macro1(new)macro_lib2a.dart=Macro2a(new)]
*/

import 'macro_lib1.dart';
import 'macro_lib2a.dart';
import 'macro_lib2b.dart';

/*member: main:appliedMacros=[
  Macro1.new,
  Macro2a.new,
  Macro2b.new]*/
@Macro1()
@Macro2a()
@Macro2b()
void main() {}
