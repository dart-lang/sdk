// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.java_engine_io;

import "dart:io";

import "package:analyzer/src/generated/java_io.dart";

class FileUtilities2 {
  static JavaFile createFile(String path) {
    return new JavaFile(path).getAbsoluteFile();
  }
}

class OSUtilities {
  static String LINE_SEPARATOR = isWindows() ? '\r\n' : '\n';
  static bool isMac() => Platform.operatingSystem == 'macos';
  static bool isWindows() => Platform.operatingSystem == 'windows';
}
