// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Stress test isolate generation.
// DartOptions=tests/standalone/src/OptionsTest.dart 10 OptionsTest 20

main() {
  var opts = new Options();

  // Basic test for functionality.
  Expect.equals(3, opts.arguments.length);
  Expect.equals(10, Math.parseInt(opts.arguments[0]));
  Expect.equals("OptionsTest", opts.arguments[1]);
  Expect.equals(20, Math.parseInt(opts.arguments[2]));

  // Now add an additional argument.
  opts.arguments.add("Fourth");
  Expect.equals(4, opts.arguments.length);
  Expect.equals(10, Math.parseInt(opts.arguments[0]));
  Expect.equals("OptionsTest", opts.arguments[1]);
  Expect.equals(20, Math.parseInt(opts.arguments[2]));
  Expect.equals("Fourth", opts.arguments[3]);

  // Check that a new options object still gets the original arguments.
  var opts2 = new Options();
  Expect.equals(3, opts2.arguments.length);
  Expect.equals(10, Math.parseInt(opts2.arguments[0]));
  Expect.equals("OptionsTest", opts2.arguments[1]);
  Expect.equals(20, Math.parseInt(opts2.arguments[2]));
}
