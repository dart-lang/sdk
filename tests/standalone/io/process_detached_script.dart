// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Simple script hanging for testing a detached process.

import 'dart:io';
import 'dart:isolate';

void main(List<String> args) {
  new ReceivePort().listen(print);

  // If an argument 'echo' is passed echo stdin to stdout and stderr.
  if (args.length == 1 && args[0] == 'echo') {
    stdin.fold([], (p, e) => p..addAll(e)).then((message) {
      stdout.add(message);
      stderr.add(message);
      stdout.close();
      stderr.close();
    });
  }
}
