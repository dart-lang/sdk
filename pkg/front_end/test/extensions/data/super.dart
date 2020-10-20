// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2]*/

class A1 {
  method1() {}
}

/*class: A2:
 builder-name=A2,
 builder-onType=A1,
 extension-members=[
  method2=A2|method2,
  tearoff method2=A2|get#method2],
 extension-name=A2,
 extension-onType=A1
*/
extension A2 on A1 {
  /*member: A2|method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=A2|method2,
   member-params=[#this]
  */
  method2() {
    /*error: errors=[SuperAsIdentifier]*/ super.method1();
  }

  /*member: A2|get#method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=A2|get#method2,
   member-params=[#this]
  */
}

main() {
}
