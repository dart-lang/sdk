// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

inline class Class1 {
  final int field;

  Class1(this.field);
}

inline class Class2 {
  final int field;

  Class2(int field) : this.field = field;
}

inline class Class3 {
  final int field;
}

inline class Class4 {
  final int field;

  Class4(this.field, this.nonexisting);
}

inline class Class5 {
  final int field;

  Class5(this.field) : this.field = 42;
}

inline class Class6 {
  final int field;

  Class6(this.field) : this.nonexisting = 42;
}
