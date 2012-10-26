#!/usr/bin/env dart
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "release/version.dart";

void main() {
  Path scriptPath = new Path.fromNative(new Options().script).directoryPath;
  Version version = new Version(scriptPath.append("VERSION"));
  Future f = version.getVersion();
  f.then((currentVersion) {
    print(currentVersion);
  });
  f.handleException((e) {
    print("Could not create version number, failed with: $e");
    return true;
  });
}
