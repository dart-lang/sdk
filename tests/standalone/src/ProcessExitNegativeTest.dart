// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test that compilation errors in the process
// exit handler is reported correctly.

void main() {
  Process p = new Process("true", []);
  p.exitHandler = (int s) {
    print(a.toString());  // Should cause a compilation error here.
    p.close();
  };
  p.start();
}
