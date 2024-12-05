// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/variable/variable_declaration_metadata_test.dart

// Verify that the individual variable declarations inside a variable
// declaration list are not allowed to be annotated with metadata.

const annotation = null;

var v0; // OK
var @annotation v1; // Error
var v2, @annotation v3; // Error

int v4 = -1;  // This should by itself be fine, but recovery is bad.
int @annotation v5 = -1; // Error --- I think this is where the bad recovery happens.
int v6 = -1, @annotation v7 = -1; // Error

class C {
  var f0; // OK
  var @annotation f1; // Error
  var f2, @annotation f3; // Error

  int f4 = -1; // This should by itself be fine, but recovery is bad.
  int @annotation f5 = -1; // Error
  int f6 = -1, @annotation f7 = -1; // Error
}

void foo() {
  var l0; // OK
  var @annotation l1; // Error
  var l2, @annotation l3; // Error

  int l4 = -1; // This should by itself be fine, but recovery is bad.
  int @annotation l5 = -1; // Error
  int l6 = -1, @annotation l7 = -1; // Error

  for (
    var @annotation i1 = 0, @annotation i2 = 0 // Error
        ;;) {
    break;
  }
}
