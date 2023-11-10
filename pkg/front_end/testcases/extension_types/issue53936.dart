// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type const E<T>(Object? o) {
  const E.cast(Object? v) : this(v as T);
}

typedef TypeAlias<T> = T;

extension type const TypeOf<T>(T _) {}

void main() {
  const E<String>.cast("a");
  const E<TypeAlias<String>>.cast("a");
  const E<TypeOf<String>>.cast("a");
  const E<String>.cast(TypeOf<String>("a"));
  const E<TypeOf<String>>.cast(TypeOf<String>("a"));
}