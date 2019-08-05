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
     builder-params=[#this],
     member-name=method1,
     member-params=[#this]
  */
  A1 method1() {
    return this;
  }

  /*member: A2.method2:
     builder-name=method2,
     builder-params=[#this,o],
     builder-type-params=[T],
     member-name=method2,
     member-params=[#this,o],
     member-type-params=[T]
  */
  A1 method2<T>(T o) {
    print(o);
    return this;
  }

  /*member: A2.method3:
     builder-name=method3,
     builder-params=[#this],
     builder-pos-params=[o],
     builder-type-params=[T],
     member-name=method3,
     member-params=[#this],
     member-pos-params=[o],
     member-type-params=[T]
  */
  A1 method3<T>([T o]) {
    print(o);
    return this;
  }

  /*member: A2.method4:
     builder-name=method4,
     builder-params=[#this],
     builder-named-params=[o],
     builder-type-params=[T],
     member-name=method4,
     member-params=[#this],
     member-named-params=[o],
     member-type-params=[T]
  */
  A1 method4<T>({T o}) {
    print(o);
    return this;
  }
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
     builder-params=[#this],
     builder-type-params=[T],
     member-name=method1,
     member-params=[#this],
     member-type-params=[#T]
  */
  B1<T> method1() {
    return this;
  }

  /*member: B2.method2:
     builder-name=method2,
     builder-params=[#this,o],
     builder-type-params=[T,S],
     member-name=method2,
     member-params=[#this,o],
     member-type-params=[#T,S]
  */
  B1<T> method2<S>(S o) {
    print(o);
    return this;
  }
}

main() {}