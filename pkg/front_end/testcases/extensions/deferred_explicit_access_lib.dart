// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  static int staticField = 0;

  static int get staticProperty => staticField;

  static void set staticProperty(int value) {
    staticField = value;
  }

  static int staticMethod() => staticField;

  int get property => this + staticField;

  void set property(int value) {
    staticField = value;
  }

  int method() => this + staticField;
}

int topLevelField = Extension.staticField;

int get topLevelProperty => Extension.staticField;

void set topLevelProperty(int value) {
  Extension.staticField = value;
}

topLevelMethod() => Extension.staticField;
