// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/21579
//
// Fails for --trust-type-annotations:
//
// test.py -mrelease -cdart2js -rd8 --dart2js-options='--trust-type-annotations' dart2js_extra/21579_test

import 'package:expect/expect.dart';

main() {
  var a = new List.generate(100, (i) => i);
  a.sort((a, b) => 1000000000000000000000 * a.compareTo(b));
  Expect.equals(0, a.first);
  Expect.equals(99, a.last);
}
