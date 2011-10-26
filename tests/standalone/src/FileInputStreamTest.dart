// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing FileInputStream, VM-only, standalone test.

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    FileUtil.fileExists(path) ? path : '../' + path;

main() {
  String fName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart\nwassup!"
  File file = new File(fName, false);
  StringInputStream x = new StringInputStream(file.inputStream);
  String line = x.readLine();
  Expect.equals("Hello Dart", line);
  file.close();
  line = x.readLine();
  Expect.equals("wassup!", line);
}
