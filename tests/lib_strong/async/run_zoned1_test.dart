// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';

main() {
  // Make sure `runZoned` returns the result of a synchronous call.
  Expect.equals(499, runZoned(() => 499));
}
