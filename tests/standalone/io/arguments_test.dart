// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=10 arguments_test 20

import "package:expect/expect.dart";

main(List<String> args) {
  // Basic test for functionality.
  Expect.equals(3, args.length);
  Expect.equals(10, int.parse(args[0]));
  Expect.equals("arguments_test", args[1]);
  Expect.equals(20, int.parse(args[2]));
  // Cannot add an additional argument.
  Expect.throws(() => args.add("Fourth"), (e) => e is UnsupportedError);
}
