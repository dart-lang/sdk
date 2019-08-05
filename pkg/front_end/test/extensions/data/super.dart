// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  method1() {}
}

/*class: A2:
 builder-name=A2,
 builder-onTypes=[A1],
 builder-supertype=Object,
 cls-name=A2,
 cls-supertype=Object
*/
extension A2 on A1 {
  /*member: A2.method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=method2,
   member-params=[#this]
  */
  method2() {
    /*error: errors=[SuperAsIdentifier]*/ super.method1();
  }
}

main() {
}