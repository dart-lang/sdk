// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

const annotation = 1;

(int, String b) topLevelFieldType = throw '';
(int a, String b) get topLevelGetterType => throw '';
(int, {String b}) topLevelMethodReturnType() => throw '';
void topLevelSetterType(({@annotation int a, String b}) value) {}
void topLevelMethodParameterType((String, @annotation int) o) {}

void method() {
  (int, String b) topLevelFieldType = throw '';
  (int a, String b) get topLevelGetterType => throw '';
  (int, {String b}) topLevelMethodReturnType() => throw '';
  void topLevelSetterType(({@annotation int a, String b}) value) {}
  void topLevelMethodParameterType((String, @annotation int) o) {}
}