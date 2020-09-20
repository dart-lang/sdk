// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class S {}

abstract class M<T> {}

abstract class N<T> {}

class C<T> extends S with M<C<T>>, N<C<T>> {}

main() {
  new C<int>();
}
