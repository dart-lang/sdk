// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[
  p1: {units: [2{step2a}], usedBy: [], needs: []},
  p2: {units: [5{step2b}], usedBy: [], needs: []},
  p3: {units: [7{step3}], usedBy: [], needs: []},
  p4: {units: [3{step2a, step3}], usedBy: [], needs: []},
  p5: {units: [6{step2b, step3}], usedBy: [], needs: []},
  p6: {units: [4{step2a, step2b, step3}], usedBy: [], needs: []},
  p7: {units: [1{step1, step2a, step2b, step3}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [2{step2a}],
  f2: [5{step2b}],
  f3: [7{step3}],
  f4: [3{step2a, step3}],
  f5: [6{step2b, step3}],
  f6: [4{step2a, step2b, step3}],
  f7: [1{step1, step2a, step2b, step3}]],
 c_steps=[
  step1=(f7),
  step2a=(f7, f6, f4, f1),
  step2b=(f7, f6, f5, f2),
  step3=(f7, f6, f5, f4, f3)]
*/
import 'step1.dart' deferred as step1;
import 'step2a.dart' deferred as step2a;
import 'step2b.dart' deferred as step2b;
import 'step3.dart' deferred as step3;

/*member: main:member_unit=main{}*/
main() {
  step1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    print(step1.step());
    step2a.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(step2a.step());
    });
    step2b.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(step2b.step());
      step3.loadLibrary().then(/*closure_unit=main{}*/ (_) {
        print(step3.step());
      });
    });
  });
}
