// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:io";

void main(List<String> args) {
  if (args.contains("--child")) {
    new RawReceivePort(); // Hang if not killed.
    Isolate.current.kill(priority: Isolate.IMMEDIATE);
    // No intervening call.
    throw "QQQ Should not be reached";
  } else {
    var exec = Platform.resolvedExecutable;
    var args = new List();
    args.addAll(Platform.executableArguments);
    args.add(Platform.script.toFilePath());
    args.add("--child");
    var result = Process.runSync(exec, args);
    if (result.exitCode != 255) {
      throw "Wrong exit code: ${result.exitCode}";
    }
    if (result.stderr.contains("QQQ Should not be reached")) {
      print(result.stderr);
      throw "Not killed synchronously";
    }
    if (!result.stderr.contains("isolate terminated by Isolate.kill")) {
      print(result.stderr);
      throw "Missing killed message";
    }
  }
}
