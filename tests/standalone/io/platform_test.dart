// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

test() {
  Expect.isTrue(Platform.numberOfProcessors > 0);
  var os = Platform.operatingSystem;
  Expect.isTrue(os == "android" || os == "linux" || os == "macos" ||
      os == "windows");
  Expect.equals(Platform.isLinux, Platform.operatingSystem == "linux");
  Expect.equals(Platform.isMacOS, Platform.operatingSystem == "macos");
  Expect.equals(Platform.isWindows, Platform.operatingSystem == "windows");
  Expect.equals(Platform.isAndroid, Platform.operatingSystem == "android");
  var sep = Platform.pathSeparator;
  Expect.isTrue(sep == '/' || (os == 'windows' && sep == '\\'));
  var hostname = Platform.localHostname;
  Expect.isTrue(hostname is String && hostname != "");
  var environment = Platform.environment;
  Expect.isTrue(environment is Map<String, String>);
  Expect.isTrue(Platform.executable.contains('dart'));
  Expect.isTrue(Platform.script.replaceAll('\\', '/').
                endsWith('tests/standalone/io/platform_test.dart'));
  Directory packageRoot = new Directory(Platform.packageRoot);
  Expect.isTrue(packageRoot.existsSync());
  Expect.isTrue(new Directory("${packageRoot.path}/expect").existsSync());
  Expect.isTrue(Platform.executableArguments.any(
      (arg) => arg.contains(Platform.packageRoot)));
}

void f() {
  port.receive((msg, reply) {
    if (msg == "Platform.executable") {
      reply.send(Platform.executable);
    }
    if (msg == "Platform.script") {
      reply.send(Platform.script);
    }
    if (msg == "Platform.packageRoot") {
      reply.send(Platform.packageRoot);
    }
    if (msg == "Platform.executableArguments") {
      reply.send(Platform.executableArguments);
    }
    if (msg == "close") {
      reply.send("closed");
      port.close();
    }
  });
}

testIsolate() {
  asyncStart();
  var sendPort = spawnFunction(f);
  Future.wait([sendPort.call("Platform.executable"),
               sendPort.call("Platform.script"),
               sendPort.call("Platform.packageRoot"),
               sendPort.call("Platform.executableArguments")])
  .then((results) {
    Expect.equals(Platform.executable, results[0]);
    Uri uri = Uri.parse(results[1]);
    // SpawnFunction retains the script url of the parent which in this
    // case was a relative path.
    Expect.equals("", uri.scheme);
    Expect.isTrue(uri.path.endsWith('tests/standalone/io/platform_test.dart'));
    Expect.equals(Platform.packageRoot, results[2]);
    Expect.listEquals(Platform.executableArguments, results[3]);
    sendPort.call("close").then((_) => asyncEnd());
  });
}

main() {
  test();
  testIsolate();
}
