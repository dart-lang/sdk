// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the GVN optimization pass works as expected.

library basic_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry.forMethod('function(foo)', r"""
foo(x, list) {
  var sum = 0;
  for (int k = 0; k < 10; k++) {
    // Everything can be hoisted out up to the index access which is
    // blocked by the bounds check.
    var a = x.left.left;
    var b = x.left.right;
    var c = x.right.left;
    var d = x.right.right;
    var i = a.value + c.value;
    var j = b.value + d.value;
    var z = list[i * j] + i;
    sum += z;
  }
  return sum;
}
// Use a different class for each level in the tree, so type inference
// is not confused.
class Root {
  Branch left, right;
  Root(this.left, this.right);
}
class Branch {
  Leaf left, right;
  Branch(this.left, this.right);
}
class Leaf {
  int value;
  Leaf(this.value);
}
main() {
  var x1 = new Leaf(1);
  var x2 = new Leaf(10);
  var x3 = new Leaf(20);
  var x4 = new Leaf(-10);
  var y1 = new Branch(x1, x2);
  var y2 = new Branch(x3, x4);
  var z  = new Root(y1, y2);
  print(foo(z, [1,2,3,4,5,6,7,8,9,10]));
}
""",r"""
function(x, list) {
  var v0 = x.left, a = v0.left, b = v0.right, sum = 0, k = 0, c = (v0 = x.right).left, d = v0.right, v1, v2, v3, i, v4;
  v0 = a.value;
  v1 = c.value;
  v2 = b.value;
  for (v3 = d.value; k < 10; sum = sum + (i + list[v4]), k = k + 1) {
    i = v0 + v1;
    v4 = i * (v2 + v3);
    if (v4 < 0 || v4 >= 10)
      return H.ioore(list, v4);
  }
  return sum;
}"""),
];

void main() {
  runTests(tests);
}
