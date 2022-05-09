// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test ensures that when a `.call` tearoff occurs on the right hand side
// of an assignment, the resulting expression has an appropriate type.

import "package:expect/expect.dart";

import '../static_type_helper.dart';

dynamic _topLevelPropertySetValue;

set topLevelProperty(void Function() value) {
  Expect.isNull(_topLevelPropertySetValue);
  _topLevelPropertySetValue = value;
}

class C {
  static dynamic _staticPropertySetValue;

  void call() {}

  static set staticProperty(void Function() value) {
    Expect.isNull(_staticPropertySetValue);
    _staticPropertySetValue = value;
  }
}

class Base {
  late final dynamic _basePropertySetValue;

  set baseProperty(void Function() value) {
    _basePropertySetValue = value;
  }
}

class Derived extends Base {
  late final dynamic _indexSetValue;
  late final dynamic _instanceSetValue;

  operator []=(int index, void Function() value) {
    _indexSetValue = value;
  }

  set instanceProperty(void Function() value) {
    _instanceSetValue = value;
  }

  void testSuperPropertySet() {
    Expect.type<void Function()>((super.baseProperty = C())
      ..expectStaticType<Exactly<void Function()>>());
    Expect.type<void Function()>(super._basePropertySetValue);
  }
}

class Extended {
  late final dynamic _extensionIndexSetValue;
  late final dynamic _extensionPropertySetValue;
}

extension on Extended {
  operator []=(int index, void Function() value) {
    _extensionIndexSetValue = value;
  }

  set extensionProperty(void Function() value) {
    _extensionPropertySetValue = value;
  }
}

void testExtensionIndexSet() {
  Extended e = Extended();
  Expect.type<void Function()>(
      (e[0] = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(e._extensionIndexSetValue);
}

void testExtensionSet() {
  Extended e = Extended();
  Expect.type<void Function()>((e.extensionProperty = C())
    ..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(e._extensionPropertySetValue);
}

void testIndexSet() {
  Derived d = Derived();
  Expect.type<void Function()>(
      (d[0] = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(d._indexSetValue);
}

void testInstanceSet() {
  Derived d = Derived();
  Expect.type<void Function()>(
      (d.instanceProperty = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(d._instanceSetValue);
}

void testNullAwarePropertySet() {
  Derived? d = Derived() as Derived?; // ignore: unnecessary_cast
  Expect.type<void Function()>((d?.instanceProperty = C())
    ..expectStaticType<Exactly<void Function()?>>());
  Expect.type<void Function()>(d!._instanceSetValue);
}

void testStaticSet() {
  C._staticPropertySetValue = null;
  Expect.type<void Function()>(
      (C.staticProperty = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(C._staticPropertySetValue);
}

void testTopLevelSet() {
  _topLevelPropertySetValue = null;
  Expect.type<void Function()>(
      (topLevelProperty = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(_topLevelPropertySetValue);
}

void testVariableSet() {
  void Function() f;
  Expect.type<void Function()>(
      (f = C())..expectStaticType<Exactly<void Function()>>());
  Expect.type<void Function()>(f);
}

main() {
  testExtensionIndexSet();
  testExtensionSet();
  testIndexSet();
  testInstanceSet();
  testStaticSet();
  Derived().testSuperPropertySet();
  testTopLevelSet();
  testVariableSet();
}
