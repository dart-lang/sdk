// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import augment 'scope_access_lib1.dart';
import augment 'scope_access_lib2.dart';

void topLevelMethod() {
  topLevelMethod();
  topLevelInjectedMethod1();
  topLevelInjectedMethod2();
  _topLevelInjectedMethod3();
}

void set topLevelSetter(value) {
  topLevelSetter = value;
  topLevelInjectedSetter1 = value;
  topLevelInjectedSetter2 = value;
  _topLevelInjectedSetter3 = value;
}

class Class {
  Class.constructor() {
    Class.constructor();
    Class.injectedConstructor1();
    Class.injectedConstructor2();
    Class._injectedConstructor3();
  }

  static void staticMethod() {
    staticMethod();
    staticInjectedMethod1();
    staticInjectedMethod2();
    _staticInjectedMethod3();
    Class.staticMethod();
    Class.staticInjectedMethod1();
    Class.staticInjectedMethod2();
    Class._staticInjectedMethod3();
  }

  static void set staticSetter(value) {
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