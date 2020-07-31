// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'non_nullable_instantiation_with_nullable_lib.dart';

main() {
  Expect.isTrue(A<int>().foo(42));
  Expect.isFalse(A<bool>().foo(42));
  Expect.isTrue(A<Null>().foo(null));
  Expect.isTrue(A<dynamic>().foo(null));
  Expect.isTrue(A<dynamic>().foo("anything"));
}
