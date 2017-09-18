// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test.
// The MirrorsUsed annotation made dart2js to mark List as needed for reflection
// but tree-shaking wasn't turned off (since there is no actual mirror use)
// which led to a broken output.

@MirrorsUsed(targets: "List")
import 'dart:mirrors';

void main() {
  var l = new List<int>();
  var f = l.retainWhere;
  f((x) => true);
}
