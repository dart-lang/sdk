// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {}

/*class: A2:
 builder-name=A2,
 builder-onTypes=[A1],
 builder-supertype=Object,
 cls-name=A2,
 cls-supertype=Object
*/
extension A2 on A1 {
  /*member: A2.method1:
     builder-name=method1,
     builder-params=[o],
     member-name=method1,
     member-params=[o]
  */
  static A1 method1(A1 o) => o;

  /*member: A2.method2:
     builder-name=method2,
     builder-params=[o],
     builder-type-params=[T],
     member-name=method2,
     member-params=[o],
     member-type-params=[T]
  */
  static T method2<T>(T o) => o;
}

class B1<T> {}

/*class: B2:
 builder-name=B2,
 builder-onTypes=[B1<T>],
 builder-supertype=Object,
 builder-type-params=[T],
 cls-name=B2,
 cls-supertype=Object,
 cls-type-params=[T]
*/
extension B2<T> on B1<T> {
  /*member: B2.method1:
     builder-name=method1,
     builder-params=[o],
     member-name=method1,
     member-params=[o]
  */
  static B1 method1(B1 o) => o;

  /*member: B2.method2:
     builder-name=method2,
     builder-params=[o],
     builder-type-params=[S],
     member-name=method2,
     member-params=[o],
     member-type-params=[S]
  */
  static S method2<S>(S o) => o;
}

main() {}