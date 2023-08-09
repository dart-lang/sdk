// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  factory A() = B<T>;
}

class B<T> implements A<T> {}

main() async {
  await A<void>();
}
