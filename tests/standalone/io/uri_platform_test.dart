// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'package:path/path.dart' as path;
import "dart:io";

main() {
  if (Platform.isWindows) {
    Expect.equals("a\\b", Uri.parse("a/b").toFilePath());
    Expect.equals("a\\b\\", Uri.parse("a/b/").toFilePath());
    Expect.equals("a b", Uri.parse("a%20b").toFilePath());
    Expect.equals("\\a b", Uri.parse("file:///a%20b").toFilePath());
    Expect.equals("\\a\\b", Uri.parse("file:///a/b").toFilePath());
    Expect.equals("C:\\", Uri.parse("file:///C:").toFilePath());
    Expect.equals("C:\\", Uri.parse("file:///C:/").toFilePath());
    Expect.equals("\\\\host\\a\\b", Uri.parse("file://host/a/b").toFilePath());

    Expect.equals("a\\b", new Uri.file("a/b").toFilePath());
    Expect.equals("a\\b", new Uri.file("a\\b").toFilePath());
    Expect.equals("\\a\\b", new Uri.file("/a/b").toFilePath());
    Expect.equals("\\a\\b", new Uri.file("\\a\\b").toFilePath());
    Expect.equals("\\a\\b", new Uri.file("\\a/b").toFilePath());
    Expect.equals("\\a\\b", new Uri.file("/a\\b").toFilePath());
  } else {
    Expect.equals("a/b", Uri.parse("a/b").toFilePath());
    Expect.equals("a/b/", Uri.parse("a/b/").toFilePath());
    Expect.equals("a b", Uri.parse("a%20b").toFilePath());
    Expect.equals("/a b", Uri.parse("file:///a%20b").toFilePath());
    Expect.equals("/a/b", Uri.parse("file:///a/b").toFilePath());
    Expect.equals("/C:", Uri.parse("file:///C:").toFilePath());
    Expect.equals("/C:/", Uri.parse("file:///C:/").toFilePath());
    Expect.throwsUnsupportedError(
        () => Uri.parse("file://host/a/b").toFilePath());

    Expect.equals("a/b", new Uri.file("a/b").toFilePath());
    Expect.equals("a\\b", new Uri.file("a\\b").toFilePath());
  }
  // If the current path is only the root prefix (/ (or c:\), then don't add a
  // separator at the end.
  Expect.equals(
      Uri.base,
      (Directory.current.path.toString() !=
              path.rootPrefix(Directory.current.path.toString()))
          ? new Uri.file(Directory.current.path + Platform.pathSeparator)
          : new Uri.file(Directory.current.path));
}
