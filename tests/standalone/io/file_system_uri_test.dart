// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";

testFile(String input) {
  if (Platform.isWindows) {
    input = input.replaceAll('/', '\\');
  }
  var file = new File(input);
  var uri = file.uri;
  var file2 = new File.fromUri(uri);
  Expect.equals(file.path, file2.path, input);
}

testDirectory(String input, [String output]) {
  if (output == null) output = input;
  if (Platform.isWindows) {
    input = input.replaceAll('/', '\\');
    output = output.replaceAll('/', '\\');
  }
  var dir = new Directory(input);
  var uri = dir.uri;
  var dir2 = new Directory.fromUri(uri);
  Expect.equals(output, dir2.path, input);
}

void main() {
  testFile("");
  testFile("/");
  testFile("foo/bar");
  testFile("/foo/bar");
  testFile("/foo/bar/");

  testDirectory("");
  testDirectory("/");
  testDirectory("foo/bar", "foo/bar/");
  testDirectory("/foo/bar", "/foo/bar/");
  testDirectory("/foo/bar/");
}
