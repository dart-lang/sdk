// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Interface:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Interface {
  /*member: Interface.implementedLateFieldDeclaredGetterSetter#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  /*member: Interface.implementedLateFieldDeclaredGetterSetter=#cls:
   classBuilder=Interface,
   isSourceDeclaration
  */
  late int implementedLateFieldDeclaredGetterSetter;
}

/*class: Class:
 interfaces=[Interface],
 maxInheritancePath=2,
 superclasses=[Object]
*/
class Class implements Interface {
/*member: Class.implementedLateFieldDeclaredGetterSetter#cls:
 classBuilder=Class,
 declared-overrides=[
  Interface.implementedLateFieldDeclaredGetterSetter,
  Interface.implementedLateFieldDeclaredGetterSetter=],
 isSourceDeclaration
*/
  int get implementedLateFieldDeclaredGetterSetter => 0;

/*member: Class.implementedLateFieldDeclaredGetterSetter=#cls:
 classBuilder=Class,
 declared-overrides=[
  Interface.implementedLateFieldDeclaredGetterSetter,
  Interface.implementedLateFieldDeclaredGetterSetter=],
 isSourceDeclaration
*/
  void set implementedLateFieldDeclaredGetterSetter(int value) {}
}
