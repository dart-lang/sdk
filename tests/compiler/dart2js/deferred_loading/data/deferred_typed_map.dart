// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../libs/deferred_typed_map_lib1.dart' deferred as lib;

/*strong.member: main:OutputUnit(main, {})*/
/*strongConst.member: main:
 OutputUnit(main, {}),
 constants=[
  MapConstant(<int, dynamic Function({M b})>{IntConstant(1): FunctionConstant(f1), IntConstant(2): FunctionConstant(f2)})=OutputUnit(1, {lib})]
*/
main() async {
  await lib.loadLibrary();
  print(lib.table[1]);
}
