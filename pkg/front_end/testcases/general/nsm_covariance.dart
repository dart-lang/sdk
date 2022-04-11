// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'nsm_covariance_lib.dart';

abstract class D1 implements A<int>, B {}

abstract class D2 implements B, A<int> {}

class D3 implements A<int>, B {
  @override
  noSuchMethod(Invocation invocation) => null;
}

class D4 implements B, A<int> {
  @override
  noSuchMethod(Invocation invocation) => null;
}

main() {}
