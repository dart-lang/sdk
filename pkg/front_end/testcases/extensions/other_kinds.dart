// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  int _instanceField;
  int getInstanceField() => _instanceField;
  void setInstanceField(int value) {
    _instanceField = value;
  }
  static int _staticField = 0;
  static int getStaticField() => _staticField;
  static void setStaticField(int value) {
    _staticField = value;
  }
}

extension A2 on A1 {
  int get instanceProperty => getInstanceField();

  void set instanceProperty(int value) {
    setInstanceField(value);
  }

  int operator +(int value) {
    return getInstanceField() + value;
  }

  int operator -(int value) {
    return getInstanceField() - value;
  }

  int operator -() {
   return -getInstanceField();
  }

  static int staticField = A1.getStaticField();

  static int get staticProperty => A1.getStaticField();

  static void set staticProperty(int value) {
    A1.setStaticField(value);
  }
}

main() {}
