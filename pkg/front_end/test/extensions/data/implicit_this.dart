// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2]*/

class A1 {
  Object field;
  void method1() {}
}

/*class: A2:
 builder-name=A2,
 builder-onType=A1,
 extension-members=[
  method2=A2|method2,
  method3=A2|method3,
  method4=A2|method4,
  tearoff method2=A2|get#method2,
  tearoff method3=A2|get#method3,
  tearoff method4=A2|get#method4],
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
  void method2() => method1();

  /*member: A2|get#method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=A2|get#method2,member-params=[#this]
  */

  /*member: A2|method3:
   builder-name=method3,
   builder-params=[#this],
   member-name=A2|method3,
   member-params=[#this]
  */
  Object method3() => field;

  /*member: A2|get#method3:
   builder-name=method3,
   builder-params=[#this],
   member-name=A2|get#method3,
   member-params=[#this]
  */

  /*member: A2|method4:
   builder-name=method4,
   builder-params=[#this,o],
   member-name=A2|method4,
   member-params=[#this,o]
  */
  void method4(Object o) {
    field = o;
  }

  /*member: A2|get#method4:
   builder-name=method4,
   builder-params=[#this,o],
   member-name=A2|get#method4,
   member-params=[#this]
  */
}

main() {
}
