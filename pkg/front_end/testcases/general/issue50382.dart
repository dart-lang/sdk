// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends B {
  A({required super.field});
}

class B {
  final int field;

  B.named({required int this.field});
}

class C extends D {
  C({required int super.field});
}

class D {
  final int field;

  D.named({required this.field});
}
