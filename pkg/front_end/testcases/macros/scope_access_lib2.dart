// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'scope_access_lib3.dart';

void topLevelInjectedMethod2() {
  topLevelMethod();
  topLevelInjectedMethod1();
  topLevelInjectedMethod2();
  _topLevelInjectedMethod3();
}

void set topLevelInjectedSetter2(value) {
  topLevelSetter = value;
  topLevelInjectedSetter1 = value;
  topLevelInjectedSetter2 = value;
  _topLevelInjectedSetter3 = value;
}

augment class Class {
  Class.injectedConstructor2() {
    Class.constructor();
    Class.injectedConstructor1();
    Class.injectedConstructor2();
    Class._injectedConstructor3();
  }

  static void staticInjectedMethod2() {
    staticMethod();
    staticInjectedMethod1();
    staticInjectedMethod2();
    _staticInjectedMethod3();
    Class.staticMethod();
    Class.staticInjectedMethod1();
    Class.staticInjectedMethod2();
    Class._staticInjectedMethod3();
  }

  static void set staticInjectedSetter2(value) {
    staticSetter = value;
    staticInjectedSetter1 = value;
    staticInjectedSetter2 = value;
    _staticInjectedSetter3 = value;
    Class.staticSetter = value;
    Class.staticInjectedSetter1 = value;
    Class.staticInjectedSetter2 = value;
    Class._staticInjectedSetter3 = value;
  }
}