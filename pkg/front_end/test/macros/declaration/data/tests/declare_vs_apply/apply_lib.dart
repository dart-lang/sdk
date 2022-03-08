// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 macrosAreApplied,
 macrosAreAvailable
*/

import 'macro_lib.dart';
import 'apply_lib_dep.dart';

/*class: Class:
 appliedMacros=[Macro1.new],
 macrosAreApplied
*/
@Macro1()
class Class extends Super {}
