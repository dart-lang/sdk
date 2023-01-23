// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[p1: {units: [1{p}], usedBy: [], needs: []}],
 b_finalized_fragments=[f1: [1{p}]],
 c_steps=[p=(f1)]
*/

/// Regression test for https://github.com/dart-lang/sdk/issues/49851
///
/// The algorithm incorrectly assumed that type variables could not occurred
/// nested within a type literal, and that most type literals were constant.
import 'lib.dart' deferred as p;

/*member: main:member_unit=main{}*/
main() async {
  await p.loadLibrary();
  print(p.A().types);
}
