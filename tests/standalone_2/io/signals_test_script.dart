// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(args) {
  int usr1Count = int.parse(args[0]);
  int usr2Count = int.parse(args[1]);
  var sub1;
  var sub2;
  void check() {
    if (usr1Count < 0 || usr2Count < 0) exit(1);
    if (usr1Count == 0 && usr2Count == 0) {
      sub1.cancel();
      sub2.cancel();
    }
    print("ready");
  }

  sub1 = ProcessSignal.SIGUSR1.watch().listen((signal) {
    if (signal != ProcessSignal.SIGUSR1) exit(1);
    usr1Count--;
    check();
  });
  sub2 = ProcessSignal.SIGUSR2.watch().listen((signal) {
    if (signal != ProcessSignal.SIGUSR2) exit(1);
    usr2Count--;
    check();
  });
  check();
}
