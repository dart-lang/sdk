// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1 {
  Void operator []=(Object key, Object value) {} // Ok
}

class Class2 {
  int operator []=(Object key, Object value) {} // Error
}

extension Extension1 on int {
  Void operator []=(Object key, Object value) {} // Ok
}

extension Extension2 on int {
  int operator []=(Object key, Object value) {} // Error
}

extension type ExtensionType1(int it) {
  Void operator []=(Object key, Object value) {} // Ok
}

extension type ExtensionType2(int it) {
  int operator []=(Object key, Object value) {} // Error
}

typedef Void = void;
