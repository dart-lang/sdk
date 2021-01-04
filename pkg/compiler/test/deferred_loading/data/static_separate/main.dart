// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec|three-frag.library: 
 output_units=[
  f1: {units: [2{lib1, lib2}], usedBy: [2, 3], needs: []},
  f2: {units: [1{lib1}], usedBy: [], needs: [1]},
  f3: {units: [3{lib2}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1, f2),
  lib2=(f1, f3)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [2{lib1, lib2}, 1{lib1}], usedBy: [2], needs: []},
  f2: {units: [3{lib2}], usedBy: [], needs: [1]}],
 steps=[
  lib1=(f1),
  lib2=(f1, f2)]
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
