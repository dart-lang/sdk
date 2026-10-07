// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_property.dart';

@annotation2
augment abstract int topLevelField1;

@annotation2
augment abstract int topLevelField2;

augment int topLevelField3 = 0;

@annotation2
augment int get topLevelFieldGetter;

@annotation2
augment void set topLevelFieldSetter(int _);

@annotation2
augment void set topLevelFieldGetterSetter(int _);

@annotation2
augment int get topLevelGetter1;

@annotation2
augment int get topLevelGetter2;

augment int get topLevelGetter3 => 0;

@annotation2
augment void set topLevelSetter1(int _);

@annotation2
augment void set topLevelSetter2(int _);

augment void set topLevelSetter3(int _) {
  print("topLevelSetter3");
}

augment abstract class Class {
  @annotation2
  augment abstract int instanceField1;

  @annotation2
  augment abstract int instanceField2;

  augment int instanceField3 = 0;

  @annotation2
  augment abstract int instanceField4;

  @annotation2
  augment int get instanceFieldGetter1;

  @annotation2
  augment int get instanceFieldGetter2;

  @annotation2
  augment void set instanceFieldSetter1(int _);

  @annotation2
  augment void set instanceFieldSetter2(int _);

  @annotation2
  augment void set instanceFieldGetterSetter1(int _);

  @annotation2
  augment void set instanceFieldGetterSetter2(int _);

  @annotation2
  augment int get instanceGetter1;

  @annotation2
  augment int get instanceGetter2;

  augment int get instanceGetter3 => 0;

  @annotation2
  augment int get instanceGetter4;

  @annotation2
  augment void set instanceSetter1(int _);

  @annotation2
  augment void set instanceSetter2(int _);

  augment void set instanceSetter3(int _) {
    print("instanceSetter3");
  }

  @annotation2
  augment void set instanceSetter4(int _);

  @annotation2
  augment static abstract int staticField1;

  @annotation2
  augment static abstract int staticField2;

  augment static int staticField3 = 0;

  @annotation2
  augment static int get staticFieldGetter;

  @annotation2
  augment static void set staticFieldSetter(int _);

  @annotation2
  augment static void set staticFieldGetterSetter(int _);

  @annotation2
  augment static int get staticGetter1;

  @annotation2
  augment static int get staticGetter2;

  augment static int get staticGetter3 => 0;

  @annotation2
  augment static void set staticSetter1(int _);

  @annotation2
  augment static void set staticSetter2(int _);

  augment static void set staticSetter3(int _) {
    print("staticSetter3");
  }
}
