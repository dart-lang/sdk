// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{lib1}], usedBy: [], needs: []}],
 steps=[lib1=(f1)]
*/

// @dart = 2.7

import 'lib1.dart' deferred as lib1;

/*member: main:
 constants=[
  ConstructedConstant(C(a=TypeConstant(void Function()),b=FunctionConstant(topLevelMethod)))=1{lib1},
  TypeConstant(void Function())=1{lib1}],
 member_unit=main{}
*/
main() async {
  await lib1.loadLibrary();
  print(lib1.cA);
  print(lib1.cB);
}
