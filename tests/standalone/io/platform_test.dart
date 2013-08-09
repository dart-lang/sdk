// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

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
}

void f() {
  port.receive((msg, reply) {
    if (msg == "Platform.executable") {
      reply.send(Platform.executable);
    }
    if (msg == "Platform.script") {
      reply.send(Platform.script);
    }
    if (msg == "new Options().executable") {
      reply.send(new Options().executable);
    }
    if (msg == "new Options().script") {
      reply.send(new Options().script);
    }
    if (msg == "close") {
      reply.send("closed");
      port.close();
    }
  });
}

testIsolate() {
  var port = new ReceivePort();
  var sendPort = spawnFunction(f);
  Future.wait([sendPort.call("Platform.executable"),
               sendPort.call("Platform.script"),
               sendPort.call("new Options().executable"),
               sendPort.call("new Options().script")])
  .then((results) {
    Expect.equals(Platform.executable, results[0]);
    Expect.equals(Platform.executable, results[2]);
    Uri uri = Uri.parse(results[1]);
    Expect.equals(uri, Uri.parse(results[3]));
    Expect.equals("file", uri.scheme);
    Expect.isTrue(uri.path.endsWith('tests/standalone/io/platform_test.dart'));
    sendPort.call("close").then((_) => port.close());
  });
}

main() {
  test();
  testIsolate();
}
