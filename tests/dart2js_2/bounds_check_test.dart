// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  var a = [0, 1];
  a[-1]; //                         //# 01: runtime error
  a[-1] = 4; //                     //# 02: runtime error
  a[2]; //                          //# 03: runtime error
  a[2] = 4; //                      //# 04: runtime error
  checkIndex(a, -1); //             //# 05: runtime error
  checkIndexedAssignment(a, -1); // //# 06: runtime error
  checkIndex(a, 2); //              //# 07: runtime error
  checkIndexedAssignment(a, 2); //  //# 08: runtime error
  checkIndex(a, 0);
  checkIndexedAssignment(a, 0);
}

checkIndex(a, b) {
  a[b];
}

checkIndexedAssignment(a, b) {
  a[b] = 1;
}
