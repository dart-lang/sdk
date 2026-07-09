// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class SuperBase<T, U> {}

abstract class Base<T> extends SuperBase<T, String> {
  T method1();
}
