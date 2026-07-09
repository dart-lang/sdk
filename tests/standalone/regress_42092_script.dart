// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

Future<void> main() async {
  var count = 0;
  ProcessSignal.sigint.watch().forEach((s) {
    count++;
    print('child: Got a SIGINT $count times, hit it 3 times to terminate');
    if (count >= 3) {
      exit(42);
    }
  });
  print('Waiting...');
  while (true) {
    await Future.delayed(const Duration(seconds: 5));
  }
}
