// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=print_sync_script.dart

import 'dart:io';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void main() {
  asyncStart();
  Process.run(
    Platform.executable,
    []
      ..addAll(Platform.executableArguments)
      ..add('--verbosity=warning')
      ..add(Platform.script.resolve('print_sync_script.dart').toFilePath()),
  ).then((out) {
    asyncEnd();
    Expect.equals(1002, out.stdout.split('\n').length);
  });
}
