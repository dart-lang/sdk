// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[
  f1: {units: [3{liba}], usedBy: [], needs: []},
  f2: {units: [1{libb}], usedBy: [], needs: []}],
 steps=[
  liba=(f1),
  libb=(f2)]
*/

import 'liba.dart' deferred as liba;
import 'libb.dart' deferred as libb;
import 'lib_shared.dart';

/*member: main:member_unit=main{}*/
main() async {
  var f = /*closure_unit=main{}*/ () => libb.C();
  print(f is C_Parent Function());
  await liba.loadLibrary();
  await libb.loadLibrary();

  print(liba.isA(libb.createA()));
  print(libb.createA());
  print(libb.createC());
  print(libb.isB(B()));
  print(liba.isD(libb.createE()));
  print(libb.isFWithUnused(null as dynamic));
}
