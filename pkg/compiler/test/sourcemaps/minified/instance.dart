// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error pattern: Instance of '([^']*)'
// Kind of minified name: global
// Expected deobfuscated name: MyClass

main() {
  throw MyClass();
}

class MyClass {}
