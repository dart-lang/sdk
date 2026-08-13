// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Class1._(int field) {
  Class1(this.field);
}

extension type Class2._(int field) {
  Class2(int field) : this.field = field;
}

extension type Class3._(int field) {}

extension type Class4._(int field) {
  Class4(this.field, this.nonexisting); // Error
}

extension type Class5._(int field) {
  Class5(this.field) : this.field = 42; // Error
}

extension type Class6._(int field) {
  Class6(this.field) : this.nonexisting = 42; // Error
}
