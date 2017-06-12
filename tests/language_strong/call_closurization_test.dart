// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization_counter_threshold=10

import "package:expect/expect.dart";

main() {
  bar(a) {
    return a is String;
  }

  var bar_tearOff = bar.call;

  for (var i = 0; i < 20; i++) {
    Expect.isFalse(bar_tearOff(1));
    Expect.isTrue(bar_tearOff.call('foo'));
    Expect.isFalse(bar_tearOff.call(1));
    Expect.isTrue(bar_tearOff('foo'));
  }

  opt_arg([a = "a"]) => a is String;
  var opt_arg_tearOff = opt_arg.call;

  for (var i = 0; i < 20; i++) {
    Expect.isFalse(opt_arg_tearOff(1));
    Expect.isFalse(opt_arg_tearOff.call(1));
    Expect.isTrue(opt_arg_tearOff());
    Expect.isTrue(opt_arg_tearOff.call());
    Expect.isTrue(opt_arg_tearOff("b"));
    Expect.isTrue(opt_arg_tearOff.call("b"));
  }

  named_arg({x: 11, y: 22}) => "$x$y";
  var named_arg_tearOff = named_arg.call;

  for (var i = 0; i < 20; i++) {
    Expect.equals("1122", named_arg_tearOff());
    Expect.equals("1122", named_arg_tearOff.call());
    Expect.equals("4455", named_arg_tearOff(y: 55, x: 44));
    Expect.equals("4455", named_arg_tearOff.call(y: 55, x: 44));
    Expect.equals("4455", named_arg_tearOff(x: 44, y: 55));
    Expect.equals("4455", named_arg_tearOff.call(x: 44, y: 55));
  }

  Expect.throws(() => bar_tearOff.call(), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => opt_arg_tearOff.call(x: "p"), (e) => e is NoSuchMethodError);
  Expect.throws(
      () => named_arg_tearOff.call("p", "q"), (e) => e is NoSuchMethodError);
}
