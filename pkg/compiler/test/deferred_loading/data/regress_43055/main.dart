// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 output_units=[f1: {units: [1{libb}], usedBy: [], needs: []}],
 steps=[libb=(f1)]
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
