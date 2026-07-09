// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Void set setter1(value) {} // Ok

int set setter2(value) {} // Error

class Class1 {
  Void set setter(value) {} // Ok
}

class Class2 {
  int set setter(value) {} // Error
}

extension Extension1 on int {
  Void set setter(value) {} // Ok
}

extension Extension2 on int {
  int set setter(value) {} // Error
}

extension type ExtensionType1(int it) {
  Void set setter(value) {} // Ok
}

extension type ExtensionType2(int it) {
  int set setter(value) {} // Error
}

typedef Void = void;
