// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is just a shell that runs the code in basic_example.dart, leaving
 * that as a library that can also be run by tests.
 */

import 'basic_example.dart';

main() {
  setup(runProgram, print);
}
