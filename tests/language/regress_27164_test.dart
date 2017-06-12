// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 27164.

import 'package:expect/expect.dart';

String simpleEcho(String arg) => arg;

class Echo {
  final echo;
  // Check that the expression simpleEcho is a compile-time constant.
  const Echo() : echo = simpleEcho;
}

void main() {
  Expect.equals("hello", const Echo().echo("hello"));
}
