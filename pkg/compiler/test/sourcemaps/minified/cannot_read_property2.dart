// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error pattern: Cannot read properties of null \(reading '([^']*)'\)
// Kind of minified name: instance
// Expected deobfuscated name: method

main() {
  MyClass().f.method(1, 2);
}

class MyClass {
  var f;
}
