// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for issue 17483.

@AssumeDynamic()
@NoInline()
confuse(x) => x;

foo(trace) {
  trace.add("foo");
  return "foo";
}

bar(trace) {
  trace.add("bar");
  return "bar";
}

main() {
  var f = confuse(foo);
  var b = confuse(bar);

  var trace = [];
  // Dart2js must keep the order of t1 and t2.
  var t1 = f(trace);
  var t2 = b(trace);
  var t3 = identical(t2, "foo");
  var t4 = trace.add(t1);
  trace.add(t3);
  trace.add(t3);
  Expect.listEquals(["foo", "bar", "foo", false, false], trace);
}
