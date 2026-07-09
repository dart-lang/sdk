// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[
  p1: {units: [2{step2a}], usedBy: [], needs: []},
  p2: {units: [4{step2b}], usedBy: [], needs: []},
  p3: {units: [3{step2a, step2b}], usedBy: [], needs: []},
  p4: {units: [1{step1, step2a, step2b}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [2{step2a}],
  f2: [4{step2b}],
  f3: [3{step2a, step2b}],
  f4: [1{step1, step2a, step2b}]],
 c_steps=[
  step1=(f4),
  step2a=(f4, f3, f1),
  step2b=(f4, f3, f2)]
*/
import 'step1.dart' deferred as step1;
import 'step2a.dart' deferred as step2a;
import 'step2b.dart' deferred as step2b;

/*member: main:member_unit=main{}*/
main() {
  step1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    print(step1.step());
    step2a.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(step2a.step());
    });
    step2b.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(step2b.step());
    });
  });
}
