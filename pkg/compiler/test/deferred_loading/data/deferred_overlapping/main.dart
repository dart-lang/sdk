// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec|three-frag.library: 
 output_units=[
  f1: {units: [1{lib1, lib2}], usedBy: [2, 3], needs: []},
  f2: {units: [2{lib1}], usedBy: [], needs: [1]},
  f3: {units: [3{lib2}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1, f2),
  lib2=(f1, f3)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [1{lib1, lib2}, 2{lib1}], usedBy: [2], needs: []},
  f2: {units: [3{lib2}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1),
  lib2=(f1, f2)]
*/

// @dart = 2.7

import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

// lib1.C1 and lib2.C2 has a shared base class. It will go in its own hunk.
/*member: main:member_unit=main{}*/
void main() {
  lib1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    new lib1.C1();
    lib2.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      new lib2.C2();
    });
  });
}
