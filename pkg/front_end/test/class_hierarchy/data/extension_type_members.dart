// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: Class:
 maxInheritancePath=1,
 superclasses=[Object]
*/
class Class {}

extension type ExtensionType1(Class c) {}

/*class: ExtensionType2:superExtensionTypes=[
  Class,
  ExtensionType1,
  Object]*/
extension type ExtensionType2(Class c) implements Class, ExtensionType1 {}