// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class W<T> {
  @pragma('vm:never-inline')
  asT(arg) => arg as T;

  @pragma('vm:never-inline')
  asNullableT(arg) => arg as T?;

  @pragma('vm:never-inline')
  asXT(arg) => arg as X<T>;

  @pragma('vm:never-inline')
  asNullableXT(arg) => arg as X<T>?;

  @pragma('vm:never-inline')
  asXNullableT(arg) => arg as X<T?>;
}

class X<T> {}

class Y {}

class Z extends Y {}
