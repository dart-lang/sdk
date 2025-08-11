// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'shared_a.dart';

B get value => B(A());

extension type B(A _internal) {
  int foo() => 1;
}
