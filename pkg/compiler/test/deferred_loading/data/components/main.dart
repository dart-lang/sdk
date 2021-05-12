// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 output_units=[
  f1: {units: [1{libA}], usedBy: [], needs: []},
  f2: {units: [3{libB, libC, libD, libE}], usedBy: [], needs: []},
  f3: {units: [2{libB}], usedBy: [], needs: []},
  f4: {units: [4{libC}], usedBy: [], needs: []},
  f5: {units: [5{libD}], usedBy: [], needs: []},
  f6: {units: [6{libE}], usedBy: [], needs: []}],
 steps=[
  libA=(f1),
  libB=(f2, f3),
  libC=(f2, f4),
  libD=(f2, f5),
  libE=(f2, f6)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [1{libA}], usedBy: [], needs: []},
  f2: {units: [3{libB, libC, libD, libE}, 6{libE}], usedBy: [], needs: [3]},
  f3: {units: [5{libD}, 4{libC}, 2{libB}], usedBy: [2], needs: []}],
 steps=[
  libA=(f1),
  libB=(f2, f3),
  libC=(f2, f3),
  libD=(f2, f3),
  libE=(f2)]
*/

/*three-frag.library: 
 output_units=[
  f1: {units: [1{libA}], usedBy: [], needs: []},
  f2: {units: [3{libB, libC, libD, libE}], usedBy: [], needs: [3, 4]},
  f3: {units: [4{libC}, 2{libB}], usedBy: [2], needs: []},
  f4: {units: [6{libE}, 5{libD}], usedBy: [2], needs: []}],
 steps=[
  libA=(f1),
  libB=(f2, f3),
  libC=(f2, f3),
  libD=(f2, f4),
  libE=(f2, f4)]
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
