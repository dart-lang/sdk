// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for issue 17483.

class A {
  var x, y;
  A(x, this.y) {
    this.x = x;
  }
  toString() => "a";
}

foo(trace) => trace.add("foo");
bar(trace) => trace.add("bar");

main() {
  var trace = [];
  // Dart2js must keep the order of t1 and t2.
  var t1 = foo(trace);
  var t2 = bar(trace);
  // Dart2js inlines the constructor, yielding something like:
  //   t3 = jsNew A(null, t2);  // Note that jsNew is pure.
  //   t3.x = t1;
  // t3 is used twice and cannot be generated at use site.
  // Dart2js must not allow t1 to cross the t3-line.
  var a = new A(t1, t2);
  // Use a. It is already implicitly used by the this.x = x line in its
  // constructor. With the following use we use it twice and make sure that
  // the allocation can not be generated at use-site.
  trace.add(a.toString());
  Expect.listEquals(["foo", "bar", "a"], trace);
}
