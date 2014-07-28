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
  // Move directory to be sure script is correct.
  var oldDir = Directory.current;
  Directory.current = Directory.current.parent;
  Expect.isTrue(Platform.script.path.
                endsWith('tests/standalone/io/platform_test.dart'));
  Expect.isTrue(Platform.script.path.startsWith(oldDir.path));
  // Restore dir.
  Directory.current = oldDir;
  Directory packageRoot = new Directory(Platform.packageRoot);
  Expect.isTrue(packageRoot.existsSync());
  Expect.isTrue(new Directory("${packageRoot.path}/expect").existsSync());
  Expect.isTrue(Platform.executableArguments.any(
      (arg) => arg.contains(Platform.packageRoot)));
}

void f(reply) {
  reply.send({"Platform.executable": Platform.executable,
              "Platform.script": Platform.script,
              "Platform.packageRoot": Platform.packageRoot,
              "Platform.executableArguments": Platform.executableArguments});
}

testIsolate() {
  asyncStart();
  ReceivePort port = new ReceivePort();
  var remote = Isolate.spawn(f, port.sendPort);
  port.first.then((results) {
    Expect.equals(Platform.executable, results["Platform.executable"]);

    Uri uri = results["Platform.script"];
    // SpawnFunction retains the script url of the parent which in this
    // case was a relative path.
    Expect.equals("file", uri.scheme);
    Expect.isTrue(uri.path.endsWith('tests/standalone/io/platform_test.dart'));
    Expect.equals(Platform.packageRoot, results["Platform.packageRoot"]);
    Expect.listEquals(Platform.executableArguments,
                      results["Platform.executableArguments"]);
    asyncEnd();
  });
}

main() {
  test();
  testIsolate();
}
