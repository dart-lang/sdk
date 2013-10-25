// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:platform" as platform;

main() {
  if (platform.operatingSystem == 'windows') {
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
    Expect.throws(() => Uri.parse("file://host/a/b").toFilePath(),
                  (e) => e is UnsupportedError);

    Expect.equals("a/b", new Uri.file("a/b").toFilePath());
    Expect.equals("a\\b", new Uri.file("a\\b").toFilePath());
  }
}
