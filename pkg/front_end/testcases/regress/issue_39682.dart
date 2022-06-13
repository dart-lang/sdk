// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import "issue_39682_lib.dart" deferred as foo;

main() {
  var f = foo.loadLibrary;
  f();
  print(__loadLibrary_foo());
}

String __loadLibrary_foo() {
  return "I'll call my methods what I want!";
}
