// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const annotation = null;

class Annotation {
  final String message;
  const Annotation(this.message);
}

class A<E> {}

class C {
  m() => new A<@annotation @Annotation("test") C>();
}

main() {}