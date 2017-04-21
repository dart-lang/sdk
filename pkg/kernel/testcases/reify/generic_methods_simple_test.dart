// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library generic_methods_simple_test;

import 'test_base.dart';

bool fun<T>(int s) {
  return true;
}

main() {
  expectTrue(fun<double>(2));
}
