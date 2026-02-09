// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Type parameters are inferred in dot shorthand static invocations.

class C<T> {
  static C<X> foo<X>(X x) => new C<X>();
  C<U> cast<U>() => new C<U>();
}

void main() {
  C<bool> c = .foo("String").cast();
}
