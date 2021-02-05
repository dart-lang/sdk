// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var a = [0, 1];
  a[1.2]; //                      //# 01: compile-time error
  a[1.2] = 4; //                  //# 02: compile-time error
  checkIndex(a, 1.4); //# 03: runtime error
  checkIndexedAssignment(a, 1.4); //# 04: runtime error
  checkIndex(a, 0);
  checkIndexedAssignment(a, 0);
}

checkIndex(a, b) {
  a[b];
}

checkIndexedAssignment(a, b) {
  a[b] = 1;
}
