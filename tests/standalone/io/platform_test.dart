// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

main() {
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
