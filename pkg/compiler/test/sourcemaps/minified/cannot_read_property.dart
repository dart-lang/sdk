// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Error pattern: Cannot read property '([^']*)' of null
// Kind of minified name: instance
// Expected deobfuscated name: method

main() {
  new MyClass().f.method();
}

class MyClass {
  var f;
}
