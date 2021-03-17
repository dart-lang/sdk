// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 output_units=[
  f1: {units: [3{libA, libB, libC}], usedBy: [], needs: []},
  f2: {units: [4{libA, libC}], usedBy: [], needs: []},
  f3: {units: [6{libA}], usedBy: [], needs: []},
  f4: {units: [5{libB, libC}], usedBy: [], needs: []},
  f5: {units: [1{libB}], usedBy: [], needs: []},
  f6: {units: [2{libC}], usedBy: [], needs: []}],
 steps=[
  libA=(f1, f2, f3),
  libB=(f1, f4, f5),
  libC=(f1, f4, f2, f6)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [3{libA, libB, libC}], usedBy: [], needs: [2]},
  f2: {units: [5{libB, libC}, 4{libA, libC}, 2{libC}], usedBy: [1], needs: [3]},
  f3: {units: [1{libB}, 6{libA}], usedBy: [2], needs: []}],
 steps=[
  libA=(f1, f2, f3),
  libB=(f1, f2, f3),
  libC=(f1, f2)]
*/

/*three-frag.library: 
 output_units=[
  f1: {units: [3{libA, libB, libC}, 5{libB, libC}, 4{libA, libC}], usedBy: [], needs: [4, 3, 2]},
  f2: {units: [6{libA}], usedBy: [1], needs: []},
  f3: {units: [1{libB}], usedBy: [1], needs: []},
  f4: {units: [2{libC}], usedBy: [1], needs: []}],
 steps=[
  libA=(f1, f2),
  libB=(f1, f3),
  libC=(f1, f4)]
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
