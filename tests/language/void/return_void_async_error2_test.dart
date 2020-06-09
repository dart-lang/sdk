// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void main() {
  test();
}

// Testing that a block bodied async function may not return non-void Future
// values
void test() async {
  return /*@compile-error=unspecified*/ null as Future<int>;
}
