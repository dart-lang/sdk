// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends B {
  A({required super.field});
}

class B {
  final int field;

  B.named({required this.field});
}
