// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class S {}

mixin M<T> {}

mixin N<T> {}

class C<T> extends S with M<C<T>>, N<C<T>> {}

main() {
  new C<int>();
}
