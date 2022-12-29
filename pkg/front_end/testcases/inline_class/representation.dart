// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Missing {}

inline class Static {
  static int staticField = 42;
  final bool instanceField;

  Static(this.instanceField);
}

inline class Multiple {
  final bool instanceField1;
  final int instanceField2;

  Multiple(this.instanceField1);
}

inline class Duplicate {
  final bool instanceField;
  final int instanceField;

  Duplicate(this.instanceField);
}