// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1<T> {}

/*class: A2:
 builder-name=A2,
 builder-onTypes=[A1<T>],
 builder-supertype=Object,
 builder-type-params=[T],
 cls-name=A2,
 cls-supertype=Object,
 cls-type-params=[T]
*/
extension A2<T> on A1<T> {
  /*member: A2.method1:
     builder-name=method1,
     builder-params=[#this],
     builder-type-params=[T,S extends T],
     member-name=method1,
     member-params=[#this],
     member-type-params=[#T,S extends #T]
  */
  A1<T> method1<S extends T>() {
    return this;
  }

  /*member: A2.method2:
     builder-name=method2,
     builder-params=[#this,o],
     builder-type-params=[T,S extends A1<T>],
     member-name=method2,
     member-params=[#this,o],
     member-type-params=[#T,S extends A1<#T>]
  */
  A1<T> method2<S extends A1<T>>(S o) {
    print(o);
    return this;
  }
}

// TODO(johnniwinther): Support F-bounded extensions. Currently the type
// variable is not recognized as a type within the bound.

main() {}