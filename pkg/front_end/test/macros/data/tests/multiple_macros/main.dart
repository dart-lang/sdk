// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:_fe_analyzer_shared/src/macros/api.dart,
  macro_lib1.dart|macro_lib2a.dart,
  macro_lib2b.dart,
  main.dart],
 macrosAreApplied,
 macrosAreAvailable
*/

import 'macro_lib1.dart';
import 'macro_lib2a.dart';
import 'macro_lib2b.dart';

@Macro1()
@Macro2a()
@Macro2b()
/*member: main:appliedMacros=[
  Macro1,
  Macro2a,
  Macro2b]*/
void main() {}
