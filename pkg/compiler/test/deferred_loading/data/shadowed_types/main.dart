// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [3{liba}], usedBy: [], needs: []},
  p2: {units: [1{libb}], usedBy: [], needs: []},
  p3: {units: [2{liba, libb}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [3{liba}],
  f2: [1{libb}]],
 c_steps=[
  liba=(f1),
  libb=(f2)]
*/

/*two-frag|three-frag.library: 
 a_pre_fragments=[
  p1: {units: [3{liba}], usedBy: [p3], needs: []},
  p2: {units: [1{libb}], usedBy: [p3], needs: []},
  p3: {units: [2{liba, libb}], usedBy: [], needs: [p1, p2]}],
 b_finalized_fragments=[
  f1: [3{liba}],
  f2: [1{libb}]],
 c_steps=[
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
