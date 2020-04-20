// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An opted-in library instantiating a non-nullable type parameter.

class A<T extends Object> {
  foo(x) => x is T;
}
