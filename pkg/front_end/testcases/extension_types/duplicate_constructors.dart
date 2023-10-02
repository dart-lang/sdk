// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int id) {
  ET1.new(this.id);
}

extension type ET2<T>(T id) {
  ET2(this.id);
}

extension type ET3.new(int id) {
  ET3(this.id);
}

extension type ET4<T>.new(T id) {
  ET4.new(this.id);
}

extension type ET5.n(int id) {
  ET5.n(this.id);
}