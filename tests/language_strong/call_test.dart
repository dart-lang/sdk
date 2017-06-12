// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10

import "package:expect/expect.dart";

main() {
  bar(a) {
    return a is String;
  }

  for (var i = 0; i < 20; i++) {
    Expect.isFalse(bar(1));
    Expect.isTrue(bar.call('foo'));
  }

  opt_arg([a = "a"]) => a is String;

  for (var i = 0; i < 20; i++) {
    Expect.isFalse(opt_arg(1));
    Expect.isFalse(opt_arg.call(1));
    Expect.isTrue(opt_arg());
    Expect.isTrue(opt_arg.call());
    Expect.isTrue(opt_arg("b"));
    Expect.isTrue(opt_arg.call("b"));
  }

  named_arg({x: 11, y: 22}) => "$x$y";

  for (var i = 0; i < 20; i++) {
    Expect.equals("1122", named_arg());
    Expect.equals("1122", named_arg.call());
    Expect.equals("4455", named_arg(y: 55, x: 44));
    Expect.equals("4455", named_arg.call(y: 55, x: 44));
    Expect.equals("4455", named_arg(x: 44, y: 55));
    Expect.equals("4455", named_arg.call(x: 44, y: 55));
  }

  Expect.throws(() => bar.call(), (e) => e is NoSuchMethodError);
  Expect.throws(() => opt_arg.call(x: "p"), (e) => e is NoSuchMethodError);
  Expect.throws(() => named_arg.call("p", "q"), (e) => e is NoSuchMethodError);
}
