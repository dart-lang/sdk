// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 declaredMacros=[Macro2b],
 macrosAreApplied,
 macrosAreAvailable
*/

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'macro_lib2a.dart';

/*class: Macro2b:
 appliedMacros=[Macro2a.new],
 macrosAreApplied
*/
@Macro2a()
macro class Macro2b implements Macro {
  const Macro2b();
}
