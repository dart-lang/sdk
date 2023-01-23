// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library used by `no_such_method_restriction_disabled_test.dart`.

// @dart=2.17

class Interface {
  static int interfaceCount = 0;

  int _privateField = 100;

  int get _privateGetter {
    interfaceCount++;
    return 101;
  }

  set _privateSetter(int value) {
    interfaceCount++;
  }

  int _privateMethod() {
    interfaceCount++;
    return 102;
  }

  int publicField = 103;

  int get publicGetter {
    interfaceCount++;
    return 104;
  }

  set publicSetter(int value) {
    interfaceCount++;
  }

  int publicMethod() {
    interfaceCount++;
    return 105;
  }

  static int getPrivateField(Interface x) => x._privateField;

  static void setPrivateField(Interface x) => x._privateField = 106;

  static int callPrivateGetter(Interface x) => x._privateGetter;

  static void callPrivateSetter(Interface x) => x._privateSetter = 107;

  static int callPrivateMethod(Interface x) => x._privateMethod();

  static int getPublicField(Interface x) => x.publicField;

  static void setPublicField(Interface x) => x.publicField = 108;

  static int callPublicGetter(Interface x) => x.publicGetter;

  static void callPublicSetter(Interface x) => x.publicSetter = 109;

  static int callPublicMethod(Interface x) => x.publicMethod();
}

class Dynamic {
  static int getPrivateField(dynamic x) => x._privateField;

  static void setPrivateField(dynamic x) => x._privateField = 103;

  static int callPrivateGetter(dynamic x) => x._privateGetter;

  static void callPrivateSetter(dynamic x) => x._privateSetter = 104;

  static int callPrivateMethod(dynamic x) => x._privateMethod();

  static int getPublicField(dynamic x) => x.publicField;

  static void setPublicField(dynamic x) => x.publicField = 108;

  static int callPublicGetter(dynamic x) => x.publicGetter;

  static void callPublicSetter(dynamic x) => x.publicSetter = 109;

  static int callPublicMethod(dynamic x) => x.publicMethod();
}

class Nsm {
  int otherNsmCount = 0;

  @override
  noSuchMethod(Invocation invocation) {
    return otherNsmCount++;
  }
}

class Stubs implements Interface {
  int stubsNsmCount = 0;

  @override
  noSuchMethod(Invocation invocation) {
    return stubsNsmCount++;
  }
}
