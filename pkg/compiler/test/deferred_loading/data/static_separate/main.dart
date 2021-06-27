// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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

// The class lib1.C is referenced via lib1
// The static function lib1.C.foo is referenced via lib2
// Dart2js will put them in separate hunks.
// Similarly for C2, ..., C5.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'lib1.dart' deferred as lib1;
import 'lib2.dart' deferred as lib2;

/*member: main:member_unit=main{}*/
void main() {
  asyncStart();
  Expect.throws(/*closure_unit=main{}*/ () {
    new lib1.C();
  });
  lib1.loadLibrary().then(/*closure_unit=main{}*/ (_) {
    lib2.loadLibrary().then(/*closure_unit=main{}*/ (_) {
      print("HERE");
      Expect.equals(1, new lib1.C().bar());
      var x = new lib1.C2();
      Expect.mapEquals({1: 2}, x.bar);
      x.bar = {2: 3};
      Expect.mapEquals({2: 3}, x.bar);

      Expect.equals(lib1.x, new lib1.C3().bar);
      Expect.mapEquals({lib1.x: lib1.x}, new lib1.C4().bar);
      Expect.equals(1, new lib1.C5().bar());

      lib2.foo();
      asyncEnd();
    });
  });
}
