// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E on int {
  void foo() {
    1.{
      this;
      return;
    };
    1.(p) {
      this;
      return;
    };
    1?.{
      this;
      return;
    };
    1?.(p) {
      this;
      return;
    };
    1..{
      this;
      return;
    };
    1..(p) {
      this;
      return;
    };
    1?..{
      this;
      return;
    };
    1?..(p) {
      this;
      return;
    };
    1.{
      return this;
    };
    1.(p) {
      return this;
    };
    1?.{
      return this;
    };
    1?.(p) {
      return this;
    };
    1..{
      return this;
    };
    1..(p) {
      return this;
    };
    1?..{
      return this;
    };
    1?..(p) {
      return this;
    };
  }
}

void main() {
  1.foo();
}
