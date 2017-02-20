// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library literals_test;

import 'test_base.dart';

class A {}

class B {}

main() {
  expectTrue(<A>[] is List<A>);
  expectTrue(<A>[] is! List<B>);

  expectTrue(<A, B>{} is Map<A, B>);
  expectTrue(<A, B>{} is! Map<A, A>);
  expectTrue(<A, B>{} is! Map<B, B>);
}
