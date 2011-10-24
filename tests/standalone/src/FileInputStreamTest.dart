// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing FileInputStream, VM-only, standalone test.


String callbackString = null;

callback(List<int> buffer) {
  callbackString =  new String.fromCharCodes(buffer);
}

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    FileUtil.fileExists(path) ? path : '../' + path;

main() {
  String fName = getFilename("tests/standalone/src/readuntil_test.dat");
  // File contains "Hello Dart, wassup!"
  File file = new File(fName, false);
  FileInputStream x = new FileInputStream(file);
  x.readUntil("Dart".charCodes(), callback);
  file.close();
  Expect.stringEquals("Hello Dart", callbackString);

  callbackString = null;
  file = new File(fName, false);
  x = new FileInputStream(file);
  x.readUntil("Darty".charCodes(), callback);
  file.close();
  Expect.isNull(callbackString);

  file = new File(fName, false);
  x = new FileInputStream(file);
  x.readUntil("wassup!".charCodes(), callback);
  file.close();
  Expect.stringEquals("Hello Dart, wassup!", callbackString);
}
