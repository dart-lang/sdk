// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.6

abstract class A2 implements Enum {
  void set index(String value) {} // Error.
  void set hashCode(double value) {} // Error.
}

mixin M2 implements Enum {
  void set index(String value) {} // Error.
  void set hashCode(double value) {} // Error.
}
