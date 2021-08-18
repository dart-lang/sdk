// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [1{lib1}], usedBy: [], needs: []},
  p2: {units: [3{lib2}], usedBy: [], needs: []},
  p3: {units: [2{lib1, lib2}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [1{lib1}],
  f2: [3{lib2}],
  f3: [2{lib1, lib2}]],
 c_steps=[
  lib1=(f3, f1),
  lib2=(f3, f2)]
*/

/*two-frag|three-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{lib1}], usedBy: [p3], needs: []},
  p2: {units: [3{lib2}], usedBy: [p3], needs: []},
  p3: {units: [2{lib1, lib2}], usedBy: [], needs: [p1, p2]}],
 b_finalized_fragments=[
  f1: [1{lib1}],
  f2: [3{lib2}],
  f3: [2{lib1, lib2}]],
 c_steps=[
  lib1=(f3, f1),
  lib2=(f3, f2)]
*/

// @dart = 2.7

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

// lib1.C1 and lib2.C2 has a shared base class. It will go in its own hunk.
/*member: main:member_unit=main{}*/
void main() {
  lib1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    print(new lib1.C1());
    lib2.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print(new lib2.C2());
    });
  });
}
