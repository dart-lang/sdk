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
  static method1=A2|method1,
  static method2=A2|method2],
 extension-name=A2,extension-onType=A1
*/
extension A2 on A1 {
  /*member: A2|method1:
     builder-name=method1,
     builder-params=[o],
     member-name=A2|method1,
     member-params=[o]
  */
  static A1 method1(A1 o) => o;

  /*member: A2|method2:
     builder-name=method2,
     builder-params=[o],
     builder-type-params=[T],
     member-name=A2|method2,
     member-params=[o],
     member-type-params=[T]
  */
  static T method2<T>(T o) => o;
}

class B1<T> {}

/*class: B2:
 builder-name=B2,
 builder-onType=B1<T>,
 builder-type-params=[T],
 extension-members=[
  static method1=B2|method1,
  static method2=B2|method2],
 extension-name=B2,
 extension-onType=B1<T>,
 extension-type-params=[T]
*/
extension B2<T> on B1<T> {
  /*member: B2|method1:
     builder-name=method1,
     builder-params=[o],
     member-name=B2|method1,
     member-params=[o]
  */
  static B1 method1(B1 o) => o;

  /*member: B2|method2:
     builder-name=method2,
     builder-params=[o],
     builder-type-params=[S],
     member-name=B2|method2,
     member-params=[o],
     member-type-params=[S]
  */
  static S method2<S>(S o) => o;
}

main() {}
