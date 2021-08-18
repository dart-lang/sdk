// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [1{libA}], usedBy: [], needs: []},
  p2: {units: [4{libB}], usedBy: [], needs: []},
  p3: {units: [6{libC}], usedBy: [], needs: []},
  p4: {units: [3{libA, libC}], usedBy: [], needs: []},
  p5: {units: [5{libB, libC}], usedBy: [], needs: []},
  p6: {units: [2{libA, libB, libC}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [1{libA}],
  f2: [4{libB}],
  f3: [6{libC}],
  f6: [2{libA, libB, libC}]],
 c_steps=[
  libA=(f6, f1),
  libB=(f6, f2),
  libC=(f6, f3)]
*/

/*two-frag.library: 
 a_pre_fragments=[
  p1: {units: [4{libB}, 1{libA}], usedBy: [p2, p3], needs: []},
  p2: {units: [3{libA, libC}, 6{libC}], usedBy: [p3], needs: [p1]},
  p3: {units: [2{libA, libB, libC}, 5{libB, libC}], usedBy: [], needs: [p2, p1]}],
 b_finalized_fragments=[
  f1: [4{libB}, 1{libA}],
  f2: [6{libC}],
  f3: [2{libA, libB, libC}]],
 c_steps=[
  libA=(f3, f1),
  libB=(f3, f1),
  libC=(f3, f2)]
*/

/*three-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{libA}], usedBy: [p4], needs: []},
  p2: {units: [4{libB}], usedBy: [p4], needs: []},
  p3: {units: [6{libC}], usedBy: [p4], needs: []},
  p4: {units: [2{libA, libB, libC}, 5{libB, libC}, 3{libA, libC}], usedBy: [], needs: [p3, p2, p1]}],
 b_finalized_fragments=[
  f1: [1{libA}],
  f2: [4{libB}],
  f3: [6{libC}],
  f4: [2{libA, libB, libC}]],
 c_steps=[
  libA=(f4, f1),
  libB=(f4, f2),
  libC=(f4, f3)]
*/

// @dart = 2.7

import 'liba.dart' deferred as libA;
import 'libb.dart' deferred as libB;
import 'libc.dart' deferred as libC;

/*member: foo:
 constants=[
  FunctionConstant(callFooMethod)=4{libB},
  FunctionConstant(createB2)=6{libC},
  FunctionConstant(createC3)=6{libC},
  FunctionConstant(createD3)=6{libC},
  FunctionConstant(createDooFunFunFoo)=6{libC},
  FunctionConstant(isDooFunFunFoo)=4{libB},
  FunctionConstant(isFoo)=1{libA},
  FunctionConstant(isFoo)=4{libB},
  FunctionConstant(isFoo)=6{libC},
  FunctionConstant(isFunFunFoo)=1{libA},
  FunctionConstant(isFunFunFoo)=4{libB},
  FunctionConstant(isFunFunFoo)=6{libC},
  FunctionConstant(isMega)=1{libA}],
 member_unit=main{}
*/
void foo() async {
  await libA.loadLibrary();
  await libB.loadLibrary();
  await libC.loadLibrary();
  print((libA.isFoo)(null as dynamic));
  print((libA.isFunFunFoo)(null as dynamic));
  print((libA.isFoo)(null as dynamic));
  print((libA.isMega)(null as dynamic));

  print((libB.isFoo)(null as dynamic));
  print((libB.callFooMethod)());
  print((libB.isFunFunFoo)(null as dynamic));
  print((libB.isDooFunFunFoo)(null as dynamic));

  print((libC.isFoo)(null as dynamic));
  print((libC.isFunFunFoo)(null as dynamic));
  print((libC.createB2)());
  print((libC.createC3)());
  print((libC.createD3)());
  print((libC.createDooFunFunFoo)());
}

/*member: main:member_unit=main{}*/
main() {
  foo();
}
