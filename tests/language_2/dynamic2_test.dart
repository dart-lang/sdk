// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test the prohibited use of 'dynamic' in extending and implementing classes.

class A
  extends dynamic // //# 00: compile-time error
  implements dynamic // //# 01: compile-time error
{}

main() {
  new A();
}
