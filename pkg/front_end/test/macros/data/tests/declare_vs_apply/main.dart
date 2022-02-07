// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  apply_lib_dep.dart|macro_lib.dart|macro_lib_dep.dart|main_lib_dep.dart|package:_fe_analyzer_shared/src/macros/api.dart,
  apply_lib.dart|main.dart],
 macroClassIds=[macro_lib.dart/Macro1],
 macroInstanceIds=[macro_lib.dart/Macro1/()],
 macrosAreAvailable,
 neededPrecompilations=[macro_lib.dart=Macro1(new)]
*/

import 'apply_lib.dart';
import 'main_lib_dep.dart';

void main() {
  new Class();
  method();
}
