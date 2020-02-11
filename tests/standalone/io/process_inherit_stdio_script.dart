// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import "package:async_helper/async_helper.dart";

void main(List<String> args) {
  String arg = args[0];
  if (arg == "--child") {
    print(args[1]);
    return;
  }
  asyncStart();
  var script =
      Platform.script.resolve('process_inherit_stdio_script.dart').toFilePath();
  var future = Process.start(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..addAll([script, "--child", "foo"]),
      mode: ProcessStartMode.inheritStdio);
  future.then((process) {
    process.exitCode.then((c) {
      asyncEnd();
    });
  });
}
