// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void main(args) {
  var signal;
  switch (args[0]) {
    case 'SIGHUP': signal = ProcessSignal.SIGHUP; break;
    case 'SIGINT': signal = ProcessSignal.SIGINT; break;
    case 'SIGTERM': signal = ProcessSignal.SIGTERM; break;
    case 'SIGUSR1': signal = ProcessSignal.SIGUSR1; break;
    case 'SIGUSR2': signal = ProcessSignal.SIGUSR2; break;
    case 'SIGWINCH': signal = ProcessSignal.SIGWINCH; break;
  }
  signal.watch().first.then((s) {
    if (signal != s) exit(1);
    if (signal.toString() != args[0]) exit(1);
    print('got signal');
  });
  print("ready");
}

