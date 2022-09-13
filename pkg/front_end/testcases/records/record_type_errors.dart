// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

() emptyType = throw '';
(int) singleType = throw '';
(int, {String}) missingName = throw '';
(var a, {var b}) missingType = throw '';
(int, {}) emptyNamedFields = throw '';
({int a, String a}) duplicateNamedFields = throw '';
({int a, String a, double a, bool b, num b}) duplicateNamedFields2 = throw '';

void method() {
  () emptyType = throw '';
  (int) singleType = throw '';
  (int, {String}) missingName = throw '';
  (var a, {var b}) missingType = throw '';
  (int, {}) emptyNamedFields = throw '';
  ({int a, String a}) duplicateNamedFields = throw '';
  ({int a, String a, double a, bool b, num b}) duplicateNamedFields2 = throw '';
}