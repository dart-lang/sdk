// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the GVN optimization pass works as expected.

library gvn_tests;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry(r"""
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
function() {
  var v0 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], sum = 0, k = 0, i, v1;
  for (; k < 10; sum = sum + (i + v0[v1]), k = k + 1) {
    i = 1 + 20;
    v1 = i * (10 + -10);
    if (v1 < 0 || v1 >= 10)
      return H.ioore(v0, v1);
  }
  v0 = H.S(sum);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
];

void main() {
  runTests(tests);
}
