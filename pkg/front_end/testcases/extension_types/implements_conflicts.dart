// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'implements_conflicts_lib.dart';

extension type ExtensionType1a(ClassA c) /* Error */
    implements ClassA, ExtensionTypeA {}

extension type ExtensionType1b(ClassA c) /* Ok */
    implements ClassA, ExtensionTypeA {
  void method1() {}
}

extension type ExtensionType2a(ClassC c) /* Error */
    implements ClassC, ExtensionTypeA, ExtensionTypeB {}

extension type ExtensionType2b(ClassC c) /* Ok */
    implements ClassC, ExtensionTypeA, ExtensionTypeB {
  void method1() {}
}

extension type ExtensionType3a(ClassC c) /* Error */
    implements ClassA, ClassB, ExtensionTypeA {}

extension type ExtensionType3b(ClassC c) /* Ok */
    implements ClassA, ClassB, ExtensionTypeA {
  void method1() {}
}

extension type ExtensionType4a(ClassC c) /* Error */
    implements ExtensionTypeA, ExtensionTypeB {}

extension type ExtensionType4b(ClassC c) /* Ok */
    implements ExtensionTypeA, ExtensionTypeB {
  void method1() {}
}

extension type ExtensionType5(ClassC c) /* Ok */
    implements ExtensionTypeA1, ExtensionTypeA2 {}

extension type ExtensionType6a(ClassF c) /* Error */
    implements ClassD, ClassE {}

extension type ExtensionType6b(ClassF c) /* Ok */
    implements ClassD, ClassE {
  void method2() {}
}

extension type ExtensionType7a(ClassF c) /* Error */
    implements ExtensionTypeD, ExtensionTypeE {}

extension type ExtensionType7b(ClassF c) /* Ok */
    implements ExtensionTypeD, ExtensionTypeE {
  void method2() {}
}


extension type ExtensionType8a(ClassI c) /* Ok */
  implements ClassG, ClassH {}

extension type ExtensionType8b(ClassI c) /* Ok */
    implements ExtensionTypeG, ExtensionTypeH {}

extension type ExtensionType9(int i) {
  void method4() {} /* Error */
  void set method4(int value) {} /* Error */
}

extension type ExtensionType9a(Never n) /* Error */
  implements ClassJ, ClassK {}

extension type ExtensionType9b(Never n) /* Error */
    implements ClassJ, ClassK {
  int get method4 => 42; /* Ok */
  void set method4(int value) {} /* Ok */
}

extension type ExtensionType10a(int i) /* Error */
    implements ExtensionTypeJ, ExtensionTypeK {}

extension type ExtensionType10b(int i) /* Ok */
   implements ExtensionTypeJ, ExtensionTypeK {
  int get method4 => 42; /* Ok */
  void set method4(int value) {} /* Ok */
}

extension type ExtensionType11(Null n) {
  int get property => 42; /* Error */
  void set property(String value) {} /* Error */
}

// TODO(johnniwinther): Remove the following errors.
extension type ExtensionType12a(Never n) /* Error */
    implements ClassL, ClassM {}

extension type ExtensionType12b(ClassL n) /* Error */
    implements ClassL {
  void set property(bool value) {} /* Error */
}

extension type ExtensionType12c(ClassM n) /* Error */
    implements ClassM {
  bool get property => true; /* Error */
}

extension type ExtensionType12d(Never n) /* Error */
    implements ClassL, ClassM {
  bool get property => true; /* Ok */
  void set property(bool value) {} /* Ok */
}

extension type ExtensionType13a(int i) /* Error */
    implements ExtensionTypeL, ExtensionTypeM {}

extension type ExtensionType13b(int i) /* Error */
    implements ExtensionTypeL {
  void set property(bool value) {} /* Error */
}

extension type ExtensionType13c(int i) /* Error */
    implements ExtensionTypeM {
  bool get property => true; /* Error */
}

extension type ExtensionType13d(int i) /* Ok */
    implements ExtensionTypeL, ExtensionTypeM {
  bool get property => true; /* Ok */
  void set property(bool value) {} /* Ok */
}
