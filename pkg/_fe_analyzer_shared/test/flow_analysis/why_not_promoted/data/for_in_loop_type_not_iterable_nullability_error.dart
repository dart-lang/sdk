// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ForInLoopTypeNotIterableNullability` or
// `ForInLoopTypeNotIterablePartNullability` errors, for which we wish to report
// "why not promoted" context information.

// TODO(paulberry): get this to work with the CFE and add additional test cases
// if needed.

class C1 {
  List<int>? bad;
}

test(C1 c) {
  if (c.bad == null) return;
  for (var x
      in /*analyzer.notPromoted(propertyNotPromoted(member:C1.bad))*/ c.bad) {}
}
