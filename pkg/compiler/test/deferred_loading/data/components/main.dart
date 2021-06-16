// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [1{libA}], usedBy: [], needs: []},
  p2: {units: [2{libB}], usedBy: [], needs: []},
  p3: {units: [4{libC}], usedBy: [], needs: []},
  p4: {units: [5{libD}], usedBy: [], needs: []},
  p5: {units: [6{libE}], usedBy: [], needs: []},
  p6: {units: [3{libB, libC, libD, libE}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [1{libA}],
  f2: [2{libB}],
  f3: [4{libC}],
  f4: [5{libD}],
  f5: [6{libE}],
  f6: [3{libB, libC, libD, libE}]],
 c_steps=[
  libA=(f1),
  libB=(f6, f2),
  libC=(f6, f3),
  libD=(f6, f4),
  libE=(f6, f5)]
*/

/*two-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{libA}], usedBy: [], needs: []},
  p2: {units: [5{libD}, 4{libC}, 2{libB}], usedBy: [p3], needs: []},
  p3: {units: [3{libB, libC, libD, libE}, 6{libE}], usedBy: [], needs: [p2]}],
 b_finalized_fragments=[
  f1: [1{libA}],
  f2: [5{libD}, 4{libC}, 2{libB}],
  f3: [3{libB, libC, libD, libE}, 6{libE}]],
 c_steps=[
  libA=(f1),
  libB=(f3, f2),
  libC=(f3, f2),
  libD=(f3, f2),
  libE=(f3)]
*/

/*three-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{libA}], usedBy: [], needs: []},
  p2: {units: [4{libC}, 2{libB}], usedBy: [p4], needs: []},
  p3: {units: [6{libE}, 5{libD}], usedBy: [p4], needs: []},
  p4: {units: [3{libB, libC, libD, libE}], usedBy: [], needs: [p2, p3]}],
 b_finalized_fragments=[
  f1: [1{libA}],
  f2: [4{libC}, 2{libB}],
  f3: [6{libE}, 5{libD}],
  f4: [3{libB, libC, libD, libE}]],
 c_steps=[
  libA=(f1),
  libB=(f4, f2),
  libC=(f4, f2),
  libD=(f4, f3),
  libE=(f4, f3)]
*/

// @dart = 2.7

import 'libA.dart' deferred as libA;
import 'libB.dart' deferred as libB;
import 'libC.dart' deferred as libC;
import 'libD.dart' deferred as libD;
import 'libE.dart' deferred as libE;

/*member: main:member_unit=main{}*/
main() async {
  await libA.loadLibrary();
  await libB.loadLibrary();
  await libC.loadLibrary();
  await libD.loadLibrary();
  await libE.loadLibrary();

  print(libA.component());
  print(libB.component());
  print(libC.component());
  print(libD.component());
  print(libE.component());
}
