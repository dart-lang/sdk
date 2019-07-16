// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'regress_27671_test.dart';

@AlwaysInline
void check(f, x) {
  assert(f(x) && true);
}
