// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "../utils.dart";
import "lib_a.dart" as libA;
import "lib_b.dart" as libB;

void main() {
  // When the name of the class is the same the error message should include
  // library URIs for the two classes.
  var a = libA.Animal();
  try {
    a as libB.Animal;
  } on TypeError catch (error) {
    var message = error.toString();
    expectStringContains(
        "Expected a value of type 'Animal' "
        "(in org-dartlang-app:/tests/dartdevc_2/cast_error/lib_b.dart)",
        message);
    expectStringContains(
        "but got one of type 'Animal' "
        "(in org-dartlang-app:/tests/dartdevc_2/cast_error/lib_a.dart)",
        message);
  }
  // Verify the libraries are properly ordered.
  var b = libB.Animal();
  try {
    b as libA.Animal;
  } on TypeError catch (error) {
    var message = error.toString();
    expectStringContains(
        "Expected a value of type 'Animal' "
        "(in org-dartlang-app:/tests/dartdevc_2/cast_error/lib_a.dart)",
        message);
    expectStringContains(
        "but got one of type 'Animal' "
        "(in org-dartlang-app:/tests/dartdevc_2/cast_error/lib_b.dart)",
        message);
  }

  // URIs are not displayed when the class names are different.
  try {
    a as String;
  } on TypeError catch (error) {
    var message = error.toString();
    expectStringContains(
        "Expected a value of type 'String', but got one of type 'Animal'",
        message);
  }
}
