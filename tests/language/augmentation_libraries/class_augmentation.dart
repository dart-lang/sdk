// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

augment library 'class_augmentation_test.dart';

augment class A {
  augment List<int> get ints => [1, 2, 3];
  augment String funcWithoutBody() => 'ab';
  augment String get getterWithoutBody => _value;
  augment set setterWithoutBody(String value) => _value = value;

  String newFunction() => 'new';
}
