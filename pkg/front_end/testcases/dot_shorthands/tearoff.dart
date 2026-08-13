// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  static C d<T>() => C<T>();
  C();
}

class C1 {
  @override
  bool operator ==(Object other) => identical(C1.new, other);
}

class A1 {
  bool operator ==(Object other) => identical(ET1.new, other);
}

extension type ET1(A1 _) implements A1 {}

void main() {
  Object o = .hash;
  print(C1() == .new);
  print(ET1(A1()) == .new);

  Object? c = C();
  if (c is C) {
    c = .d<int>;
  }
}
