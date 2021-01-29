// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{lib}], usedBy: [], needs: []}],
 steps=[lib=(f1)]
*/

// @dart = 2.7

import 'lib1.dart' deferred as lib;

/*member: main:
 constants=[MapConstant(<int*, dynamic Function({M* b})*>{IntConstant(1): FunctionConstant(f1), IntConstant(2): FunctionConstant(f2)})=1{lib}],
 member_unit=main{}
*/
main() async {
  await lib.loadLibrary();
  print(lib.table[1]);
}
