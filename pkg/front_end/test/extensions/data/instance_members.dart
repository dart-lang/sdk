// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2,B2]*/

class A1 {}

/*class: A2:
 builder-name=A2,
 builder-onType=A1,
 extension-members=[
  method1=A2|method1,
  method2=A2|method2,
  method3=A2|method3,
  method4=A2|method4,
  tearoff method1=A2|get#method1,
  tearoff method2=A2|get#method2,
  tearoff method3=A2|get#method3,
  tearoff method4=A2|get#method4],
 extension-name=A2,
 extension-onType=A1
*/
extension A2 on A1 {
  /*member: A2|method1:
     builder-name=method1,
     builder-params=[#this],
     member-name=A2|method1,
     member-params=[#this]
  */
  A1 method1() {
    return this;
  }

  /*member: A2|get#method1:
   builder-name=method1,
   builder-params=[#this],
   member-name=A2|get#method1,
   member-params=[#this]
  */

  /*member: A2|method2:
     builder-name=method2,
     builder-params=[#this,o],
     builder-type-params=[T],
     member-name=A2|method2,
     member-params=[#this,o],
     member-type-params=[T]
  */
  A1 method2<T>(T o) {
    print(o);
    return this;
  }

  /*member: A2|get#method2:
   builder-name=method2,
   builder-params=[#this,o],
   builder-type-params=[T],
   member-name=A2|get#method2,
   member-params=[#this]
  */

  /*member: A2|method3:
     builder-name=method3,
     builder-params=[#this],
     builder-pos-params=[o],
     builder-type-params=[T],
     member-name=A2|method3,
     member-params=[#this],
     member-pos-params=[o],
     member-type-params=[T]
  */
  A1 method3<T>([T o]) {
    print(o);
    return this;
  }

  /*member: A2|get#method3:
   builder-name=method3,
   builder-params=[#this],
   builder-pos-params=[o],
   builder-type-params=[T],
   member-name=A2|get#method3,
   member-params=[#this]
  */

  /*member: A2|method4:
     builder-name=method4,
     builder-params=[#this],
     builder-named-params=[o],
     builder-type-params=[T],
     member-name=A2|method4,
     member-params=[#this],
     member-named-params=[o],
     member-type-params=[T]
  */
  A1 method4<T>({T o}) {
    print(o);
    return this;
  }

  /*member: A2|get#method4:
   builder-name=method4,
   builder-named-params=[o],
   builder-params=[#this],
   builder-type-params=[T],
   member-name=A2|get#method4,
   member-params=[#this]
  */
}

class B1<T> {}

/*class: B2:
 builder-name=B2,
 builder-onType=B1<T>,
 builder-type-params=[T],
 extension-members=[
  method1=B2|method1,
  method2=B2|method2,
  tearoff method1=B2|get#method1,
  tearoff method2=B2|get#method2],
 extension-name=B2,
 extension-onType=B1<T>,
 extension-type-params=[T]
*/
extension B2<T> on B1<T> {
  /*member: B2|method1:
     builder-name=method1,
     builder-params=[#this],
     builder-type-params=[T],
     member-name=B2|method1,
     member-params=[#this],
     member-type-params=[T]
  */
  B1<T> method1() {
    return this;
  }

  /*member: B2|get#method1:
   builder-name=method1,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=B2|get#method1,
   member-params=[#this],
   member-type-params=[T]
  */

  /*member: B2|method2:
     builder-name=method2,
     builder-params=[#this,o],
     builder-type-params=[T,S],
     member-name=B2|method2,
     member-params=[#this,o],
     member-type-params=[T,S]
  */
  B1<T> method2<S>(S o) {
    print(o);
    return this;
  }

  /*member: B2|get#method2:
   builder-name=method2,
   builder-params=[#this,o],
   builder-type-params=[T,S],
   member-name=B2|get#method2,
   member-params=[#this],
   member-type-params=[T]
  */
}

main() {}
