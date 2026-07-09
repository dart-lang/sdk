// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

void method(covariant int i) /* Error */ {}
void setter(covariant int x) /* Error */ {}

extension type ET1(num id) {
  void method(covariant int i) /* Error */ {}
}

extension type ET2<T extends num>(T id) {
  void setter(covariant int x) /* Error */ {}
}

extension type ET3(num id) {
  int operator +(covariant int other) /* Error */ => other + id.floor();
}

extension type ET4(covariant num id) /* Error */ {}

extension type ET5(required num id) /* Error */ {}
