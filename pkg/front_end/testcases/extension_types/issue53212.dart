// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1(int foo) {
  E1.named(this.foo, super.bar); // Error.
}

extension type E2(int foo) {
  E2.named(this.foo, {required super.bar}); // Error.
}

extension type E3(int foo) {
  E3.named(this.foo, [super.bar = null]);
}
