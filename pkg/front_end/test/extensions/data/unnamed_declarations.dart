// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {}

/*class: extension#0:
 builder-name=extension#0,
 builder-onType=A1,
 extension-members=[method=extension#0|method],
 extension-name=extension#0,
 extension-onType=A1
*/
extension on A1 {
  /*member: extension#0|method:
     builder-name=method,
     builder-params=[#this],
     member-name=extension#0|method,
     member-params=[#this]
  */
  method() {}
}

/*class: extension#1:
 builder-name=extension#1,
 builder-onType=A1,
 extension-members=[method=extension#1|method],
 extension-name=extension#1,
 extension-onType=A1
*/
extension on A1 {
  /*member: extension#1|method:
     builder-name=method,
     builder-params=[#this],
     member-name=extension#1|method,
     member-params=[#this]
  */
  method() {}
}

class B1<T> {}

/*class: extension#2:
 builder-name=extension#2,
 builder-onType=B1<T>,
 builder-type-params=[T],
 extension-members=[method=extension#2|method],
 extension-name=extension#2,
 extension-onType=B1<T>,
 extension-type-params=[T]
*/
extension <T> on B1<T> {
  /*member: extension#2|method:
     builder-name=method,
     builder-params=[#this],
     builder-type-params=[T],
     member-name=extension#2|method,
     member-params=[#this],
     member-type-params=[#T]
  */
  method() {}
}

/*class: extension#3:
 builder-name=extension#3,
 builder-onType=B1<A1>,
 extension-members=[method=extension#3|method],
 extension-name=extension#3,
 extension-onType=B1<A1>
*/
extension on B1<A1> {
  /*member: extension#3|method:
     builder-name=method,
     builder-params=[#this],
     member-name=extension#3|method,
     member-params=[#this]
  */
  method() {}
}

/*class: extension#4:
 builder-name=extension#4,
 builder-onType=B1<T>,
 builder-type-params=[T extends A1],
 extension-members=[method=extension#4|method],
 extension-name=extension#4,
 extension-onType=B1<T>,
 extension-type-params=[T extends A1]
*/
extension <T extends A1> on B1<T> {
  /*member: extension#4|method:
     builder-name=method,
     builder-params=[#this],
     builder-type-params=[T extends A1],
     member-name=extension#4|method,
     member-params=[#this],
     member-type-params=[#T extends A1]
  */
  method() {}
}

main() {}
