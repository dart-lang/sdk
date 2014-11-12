// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test write barrier verification mode.
// VMOptions=--verified_mem --verify_before_gc --verify_after_gc

var a = [];

void main() {
  for (int i = 0; i < 123; ++i) {
    a.add(new List(12345));
  }
  for (int i = 0; i < 12345; ++i) {
    a[0] = new List(100000);
  }
}
