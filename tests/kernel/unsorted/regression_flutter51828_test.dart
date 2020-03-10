// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for https://github.com/flutter/flutter/issues/51828
// which failed due bad reuse/typing of temp. vars. in the async transform.

class A {
  Future<void> foo(x) async {}
}

class B {
  Future<void> bar(x) async {}
}

main() async => [A().foo(await null), B().bar(await null)];
