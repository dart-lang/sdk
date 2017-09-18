// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library IsolateImportNegativeTest;

// Omitting the following import is an error:
/* // //# 01: runtime error, compile-time error
import 'dart:isolate';
*/ // //# 01: continued
import 'package:async_helper/async_helper.dart';

void entry(msg) {}

main() {
  asyncStart();
  Isolate.spawn(entry, null).whenComplete(asyncEnd);
}
