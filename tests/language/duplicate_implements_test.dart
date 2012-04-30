// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that duplicate types in implements/extends list are
// compile-time errors.

interface I { }
interface J { }
interface K<T> { }

class X implements I, J, I { }               /// 01: compile-time error
class X implements J, I, K<int>, K<int> { }  /// 02: compile-time error

interface Z extends I, J, J { }              /// 03: compile-time error
interface Z extends K<int>, K<int> { }       /// 04: compile-time error

main() {
  return null;
}
