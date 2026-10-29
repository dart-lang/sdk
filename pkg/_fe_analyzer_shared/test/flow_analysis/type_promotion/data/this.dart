// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that prior to the language feature `this-promotion`,
// `this` could not be promoted, even if it appeared in an extension method.

// @dart=3.14

class C {
  void insideClass() {
    if (this is D) {
      this;
    }
  }
}

class D extends C {}

extension on C {
  void insideExtension() {
    if (this is D) {
      this;
    }
  }
}
