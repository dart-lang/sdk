// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[p1: {units: [1{libb}], usedBy: [], needs: []}],
 b_finalized_fragments=[f1: [1{libb}]],
 c_steps=[libb=(f1)]
*/

// @dart = 2.7
import 'libb.dart' deferred as libb;
import 'libc.dart';

/*member: main:member_unit=main{}*/
main() async {
  var f = /*closure_unit=main{}*/ () => libb.C1();
  print(f is C2 Function());
  print(f is C3 Function());
  await libb.loadLibrary();
}
