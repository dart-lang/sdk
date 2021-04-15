// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [6{libA}], usedBy: [], needs: []},
  p2: {units: [1{libB}], usedBy: [], needs: []},
  p3: {units: [2{libC}], usedBy: [], needs: []},
  p4: {units: [4{libA, libC}], usedBy: [], needs: []},
  p5: {units: [5{libB, libC}], usedBy: [], needs: []},
  p6: {units: [3{libA, libB, libC}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [6{libA}],
  f2: [1{libB}],
  f3: [2{libC}],
  f6: [3{libA, libB, libC}]],
 c_steps=[
  libA=(f6, f1),
  libB=(f6, f2),
  libC=(f6, f3)]
*/

/*two-frag.library: 
 a_pre_fragments=[
  p1: {units: [6{libA}], usedBy: [p3], needs: []},
  p2: {units: [1{libB}], usedBy: [p3], needs: []},
  p3: {units: [3{libA, libB, libC}, 5{libB, libC}, 4{libA, libC}, 2{libC}], usedBy: [], needs: [p2, p1]}],
 b_finalized_fragments=[
  f1: [6{libA}],
  f2: [1{libB}],
  f3: [3{libA, libB, libC}, 2{libC}]],
 c_steps=[
  libA=(f3, f1),
  libB=(f3, f2),
  libC=(f3)]
*/

/*three-frag.library: 
 a_pre_fragments=[
  p1: {units: [6{libA}], usedBy: [p4], needs: []},
  p2: {units: [1{libB}], usedBy: [p4], needs: []},
  p3: {units: [2{libC}], usedBy: [p4], needs: []},
  p4: {units: [3{libA, libB, libC}, 5{libB, libC}, 4{libA, libC}], usedBy: [], needs: [p3, p2, p1]}],
 b_finalized_fragments=[
  f1: [6{libA}],
  f2: [1{libB}],
  f3: [2{libC}],
  f4: [3{libA, libB, libC}]],
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
  FunctionConstant(callFooMethod)=1{libB},
  FunctionConstant(createB2)=2{libC},
  FunctionConstant(createC3)=2{libC},
  FunctionConstant(createD3)=2{libC},
  FunctionConstant(createDooFunFunFoo)=2{libC},
  FunctionConstant(isDooFunFunFoo)=1{libB},
  FunctionConstant(isFoo)=1{libB},
  FunctionConstant(isFoo)=2{libC},
  FunctionConstant(isFoo)=6{libA},
  FunctionConstant(isFunFunFoo)=1{libB},
  FunctionConstant(isFunFunFoo)=2{libC},
  FunctionConstant(isFunFunFoo)=6{libA},
  FunctionConstant(isMega)=6{libA}],
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
