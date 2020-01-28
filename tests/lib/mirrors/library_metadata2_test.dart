// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'library_metadata2_lib1.dart';

import 'library_metadata2_lib2.dart'; //# 01: compile-time error

void main() {
  for (var library in currentMirrorSystem().libraries.values) {
    print(library.metadata); // Processing @MyConst() in lib2 results in a
    // delayed compilation error here.
  }
}
