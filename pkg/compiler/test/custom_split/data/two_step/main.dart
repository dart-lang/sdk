// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[
  p1: {units: [3{step3}], usedBy: [], needs: []},
  p2: {units: [2{step2, step3}], usedBy: [], needs: []},
  p3: {units: [1{step1, step2, step3}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [3{step3}],
  f2: [2{step2, step3}],
  f3: [1{step1, step2, step3}]],
 c_steps=[
  step1=(f3),
  step2=(f3, f2),
  step3=(f3, f2, f1)]
*/
import 'step1.dart' deferred as step1;
import 'step2.dart' deferred as step2;
import 'step3.dart' deferred as step3;

/*member: main:member_unit=main{}*/
main() {
  step1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    print(step1.step());
    step2.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(step2.step());
      step3.loadLibrary().then(/*closure_unit=main{}*/ (_) {
        print(step3.step());
      });
    });
  });
}
