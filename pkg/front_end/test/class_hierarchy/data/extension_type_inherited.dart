// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


extension type ExtensionType(int id) {
  /*member: ExtensionType.id:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */

  /*member: ExtensionType.method:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  void method() {}

  /*member: ExtensionType.getter:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  int get getter => id;
  /*member: ExtensionType.setter=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  void set setter(int value) {}

  /*member: ExtensionType.[]:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  int operator[] (int index) => id;

  /*member: ExtensionType.staticField:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType.staticField=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static int staticField = 42;

  /*member: ExtensionType.staticMethod:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static void staticMethod() {}

  /*member: ExtensionType.staticGetter:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static int get staticGetter => 42;

  /*member: ExtensionType.staticSetter=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static void set staticSetter(int value) {}
}

/*class: ExtensionType1:superExtensionTypes=[ExtensionType]*/
extension type ExtensionType1(ExtensionType et) implements ExtensionType {
  /*member: ExtensionType1.et:
   extensionTypeBuilder=ExtensionType1,
   isSourceDeclaration
  */
  /*member: ExtensionType1.id:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType1.method:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType1.getter:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType1.[]:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType1.setter=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
}

/*class: Class:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Class {
  /*member: Class.field#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  /*member: Class.field=#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  int field = 42;
  /*member: Class.method#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  void method() {}
  /*member: Class.getter#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  int get getter => id;
  /*member: Class.setter=#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  void set setter(int value) {}
  /*member: Class.[]#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  int operator[] (int index) => id;
  /*member: Class.staticField#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  /*member: Class.staticField=#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  static int staticField = 42;
  /*member: Class.staticMethod#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  static void staticMethod() {}
  /*member: Class.staticGetter#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  static int get staticGetter => 42;
  /*member: Class.staticSetter=#cls:
   classBuilder=Class,
   isSourceDeclaration
  */
  static void set staticSetter(int value) {}
}

/*class: ExtensionType2:superExtensionTypes=[
  Class,
  Object]*/
extension type ExtensionType2(Class c) implements Class {
  /*member: ExtensionType2.field:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.method:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.getter:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.[]:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.field=:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.setter=:
   classBuilder=Class,
   isSourceDeclaration,
   nonExtensionTypeMember
  */
  /*member: ExtensionType2.c:
   extensionTypeBuilder=ExtensionType2,
   isSourceDeclaration
  */
}
