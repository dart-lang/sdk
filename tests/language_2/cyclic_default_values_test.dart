// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

bar([x = foo]) => x((_) => "bar");
foo([y = bar]) => y((_) => "foo");

foo2({f: bar2}) => f(f: ({f}) => "foo2");
bar2({f: foo2}) => f(f: ({f}) => "bar2");

main() {
  var f = bar;
  Expect.equals("bar", Function.apply(f, []));
  Expect.equals("main", Function.apply(f, [(_) => "main"]));

  var f_2 = bar2;
  Expect.equals("bar2", Function.apply(f_2, []));
  Expect.equals("main2", Function.apply(f_2, [], {#f: ({f}) => "main2"}));
}
