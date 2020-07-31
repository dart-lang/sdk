// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

import 'package:expect/expect.dart';
import 'dart:async';
import 'dart:_runtime' as dart;

void main() async {
  await timeoutTest();
  await periodicTest();
}

void timeoutTest() async {
  bool beforeRestart = true;
  bool calledBeforeRestart = false;
  bool calledAfterRestart = false;
  void callback() {
    if (beforeRestart) {
      calledBeforeRestart = true;
    } else {
      calledAfterRestart = true;
    }
  }

  Timer(Duration(milliseconds: 500), callback);
  dart.hotRestart();
  beforeRestart = false;
  await new Future.delayed(Duration(milliseconds: 600));
  Expect.isFalse(calledBeforeRestart);
  Expect.isFalse(calledAfterRestart);
}

void periodicTest() async {
  bool beforeRestart = true;
  bool calledBeforeRestart = false;
  bool calledAfterRestart = false;
  void callback(_) {
    if (beforeRestart) {
      calledBeforeRestart = true;
    } else {
      calledAfterRestart = true;
    }
  }

  Timer.periodic(Duration(milliseconds: 10), callback);
  await new Future.delayed(Duration(milliseconds: 100));
  dart.hotRestart();
  beforeRestart = false;
  await new Future.delayed(Duration(milliseconds: 100));
  Expect.isTrue(calledBeforeRestart);
  Expect.isFalse(calledAfterRestart);
}
