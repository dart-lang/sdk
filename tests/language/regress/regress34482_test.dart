// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

main() {
  Future f = new Future(() => 12345);
  Future<FutureOr> f1 = f;

  FutureOr fo = f;
  f1 = fo as Future<FutureOr>;
}
