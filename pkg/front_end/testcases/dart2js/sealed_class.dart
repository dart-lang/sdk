// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class Class {
  final int value;

  Class(this.value);
}

class A extends Class {
  A(super.value);
}

class B extends Class {
  B(super.value);
}
