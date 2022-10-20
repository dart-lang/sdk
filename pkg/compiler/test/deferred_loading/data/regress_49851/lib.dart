// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: B:
 class_unit=none,
 type_unit=1{p}
*/
class B<T> {}

/*class: A:
 class_unit=1{p},
 type_unit=1{p}
*/
/*member: A.:member_unit=1{p}*/
class A<T> {
  /*member: A.types:member_unit=1{p}*/
  Iterable<Type> get types => [B<T>];
}
