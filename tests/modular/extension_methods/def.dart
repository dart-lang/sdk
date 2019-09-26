// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int field;

  Class(this.field);
}

extension Extension on Class {
  int method() => this.field;

  int methodWithOptionals([int a = 42]) => a;

  int get property => this.field;

  void set property(int value) {
    this.field = value;
  }

  int _privateMethod() => this.field;

  static int staticField = 87;

  static int staticMethod() => staticField;

  static int get staticProperty => staticField;

  static void set staticProperty(int value) {
    staticField = value;
  }
}

extension /*UnnamedExtension*/ on Class {
  int method() => this.field + 1;
}

extension _PrivateExtension on Class {
  int method() => this.field + 2;
}

class GenericClass<T> {
  T field;

  GenericClass(this.field);
}

extension GenericExtension<T> on GenericClass<T> {
  T method() => this.field;

  T get property => this.field;

  void set property(T value) {
    this.field = value;
  }
}