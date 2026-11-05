// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'unordered_property.dart';

@annotation1
augment abstract int topLevelField1;

augment int topLevelField2 = 0;

@annotation2
augment abstract int topLevelField3;

@annotation1
augment int get topLevelFieldGetter;

@annotation1
augment void set topLevelFieldSetter(int _);

@annotation1
augment int get topLevelFieldGetterSetter;

@annotation1
augment int get topLevelGetter1;

augment int get topLevelGetter2 => 0;

@annotation2
augment int get topLevelGetter3;

@annotation1
augment void set topLevelSetter1(int _);

augment void set topLevelSetter2(int _) {
  print("topLevelSetter2");
}

@annotation2
augment void set topLevelSetter3(int _);

augment abstract class Class {
  @annotation1
  augment abstract int instanceField1;

  augment int instanceField2 = 0;

  @annotation2
  augment abstract int instanceField3;

  @annotation1
  augment abstract int instanceField4;

  @annotation1
  augment int get instanceFieldGetter1;

  @annotation1
  augment int get instanceFieldGetter2;

  @annotation1
  augment void set instanceFieldSetter1(int _);

  @annotation1
  augment void set instanceFieldSetter2(int _);

  @annotation1
  augment int get instanceFieldGetterSetter1;

  @annotation1
  augment int get instanceFieldGetterSetter2;

  @annotation1
  augment int get instanceGetter1;

  augment int get instanceGetter2 => 0;

  @annotation2
  augment int get instanceGetter3;

  @annotation1
  augment int get instanceGetter4;

  @annotation1
  augment void set instanceSetter1(int _);

  augment void set instanceSetter2(int _) {
    print("instanceSetter2");
  }

  @annotation2
  augment void set instanceSetter3(int _);

  @annotation1
  augment void set instanceSetter4(int _);

  @annotation1
  augment static abstract int staticField1;

  augment static int staticField2 = 0;

  @annotation2
  augment static abstract int staticField3;

  @annotation1
  augment static int get staticFieldGetter;

  @annotation1
  augment static void set staticFieldSetter(int _);

  @annotation1
  augment static int get staticFieldGetterSetter;

  @annotation1
  augment static int get staticGetter1;

  augment static int get staticGetter2 => 0;

  @annotation2
  augment static int get staticGetter3;

  @annotation1
  augment static void set staticSetter1(int _);

  augment static void set staticSetter2(int _) {
    print("staticSetter2");
  }

  @annotation2
  augment static void set staticSetter3(int _);
}
