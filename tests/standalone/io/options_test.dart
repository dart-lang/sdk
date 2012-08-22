// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Stress test isolate generation.
// DartOptions=tests/standalone/io/options_test.dart 10 options_test 20

#import('dart:math');

main() {
  var opts = new Options();

  // Basic test for functionality.
  Expect.equals(3, opts.arguments.length);
  Expect.equals(10, parseInt(opts.arguments[0]));
  Expect.equals("options_test", opts.arguments[1]);
  Expect.equals(20, parseInt(opts.arguments[2]));
  Expect.isTrue(opts.executable.contains('dart'));
  Expect.isTrue(opts.script.replaceAll('\\', '/').
                endsWith('tests/standalone/io/options_test.dart'));

  // Now add an additional argument.
  opts.arguments.add("Fourth");
  Expect.equals(4, opts.arguments.length);
  Expect.equals(10, parseInt(opts.arguments[0]));
  Expect.equals("options_test", opts.arguments[1]);
  Expect.equals(20, parseInt(opts.arguments[2]));
  Expect.equals("Fourth", opts.arguments[3]);

  // Check that a new options object still gets the original arguments.
  var opts2 = new Options();
  Expect.equals(3, opts2.arguments.length);
  Expect.equals(10, parseInt(opts2.arguments[0]));
  Expect.equals("options_test", opts2.arguments[1]);
  Expect.equals(20, parseInt(opts2.arguments[2]));
}
