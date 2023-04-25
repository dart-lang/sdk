// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef SourceLocation = int;

abstract class FieldRef {
  int get location;
}

abstract class FuncRef {
  int get location;
}

abstract class ClassRef {
  int get location;
}

foo(Object object) {
  final SourceLocation? sourceLocation = switch (object) {
      FieldRef(:final location) ||
      FuncRef(:final location) ||
      ClassRef(:final location) =>
        location,
      _ => null,
  };
}
