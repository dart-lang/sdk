// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Super:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Super {
  /*member: Super.extendedFieldDeclaredMethod#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  /*member: Super.extendedFieldDeclaredMethod=#cls:
   classBuilder=Super,
   isSourceDeclaration
  */
  int extendedFieldDeclaredMethod = 0;
}

/*class: Class:
 maxInheritancePath=2,
 superclasses=[
  Object,
  Super]
*/
/*member: Class.extendedFieldDeclaredMethod=#cls:
 classBuilder=Super,
 isSourceDeclaration
*/
class Class extends Super {
  /*member: Class.extendedFieldDeclaredMethod#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  void extendedFieldDeclaredMethod() {}
}
