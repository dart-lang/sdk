// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.method#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int method(int i) => i;
}

/*class: SuperQ:
 maxInheritancePath=1,
 superclasses=[Object]
*/
abstract class SuperQ {
  /*member: SuperQ.method#cls:
   classBuilder=SuperQ,
   isSourceDeclaration
  */
  int? method(int? i) => i;
}
