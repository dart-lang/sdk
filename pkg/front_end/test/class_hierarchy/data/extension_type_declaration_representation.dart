// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type I(int id) {
  /*member: I.id:
   extensionTypeBuilder=I,
   isSourceDeclaration
  */
  /*member: I.id=:
   extensionTypeBuilder=I,
   isSourceDeclaration
  */
  void set id(int i) {}
}

extension type ET1(int id) {
  /*member: ET1.id:
   extensionTypeBuilder=ET1,
   isSourceDeclaration
  */
  /*member: ET1.id=:
   extensionTypeBuilder=ET1,
   isSourceDeclaration
  */
  void set id(int i) {}
}

/*class: ET2:superExtensionTypes=[I]*/
extension type ET2(int id) implements I {
  /*member: ET2.id:
   extensionTypeBuilder=ET2,
   isSourceDeclaration
  */
  /*member: ET2.id=:
   extensionTypeBuilder=I,
   isSourceDeclaration
  */
}