// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:expect/expect.dart';

void testUnbalancedStartFinish() {
  Timeline.startSync('A');
  Timeline.finishSync();

  bool exceptionCaught = false;
  try {
    Timeline.finishSync();
  } catch (e) {
    exceptionCaught = true;
  }
  Expect.isTrue(exceptionCaught);
}

void main() {
  testUnbalancedStartFinish();
}
