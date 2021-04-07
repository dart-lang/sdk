// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 a_pre_fragments=[p1: {units: [1{s1, s2}], usedBy: [], needs: []}],
 b_finalized_fragments=[f1: [1{s1, s2}]],
 c_steps=[
  s1=(f1),
  s2=(f1)]
*/

// @dart = 2.7

/// Regression test for issue https://github.com/dart-lang/sdk/issues/31306.
///
/// When 1 constant was imported in two libraries by using the same exact
/// deferred import URI, the deferred-constant initializer was incorrectly moved
/// to the main output unit.

import 'lib_a.dart';
import 'lib_b.dart';

/*member: main:member_unit=main{}*/
main() async {
  (await doA()).method();
  await doB();
}
