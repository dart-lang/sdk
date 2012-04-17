// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");

main() {
  var p = new Platform();
  Expect.isTrue(p.numberOfProcessors() > 0);
  var os = p.operatingSystem();
  Expect.isTrue(os == "linux" || os == "macos" || os == "windows");
  var sep = p.pathSeparator();
  Expect.isTrue(sep == '/' || (os == 'windows' && sep == '\\'));
  var hostname = p.localHostname();
  Expect.isTrue(hostname is String && hostname != "");
  var environment = p.environment();
  Expect.isTrue(environment is Map<String, String>);
}
