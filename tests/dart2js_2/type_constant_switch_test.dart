// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that switching on type literals leads to a compile time error in
// dart2js since its implementation of [Type] implements 'operator =='.

class C {}

var v;

main() {
  switch (v) {
    case C: break; // //# 01: compile-time error
  }
}
