// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  const C();
}

void main() {
  var {const C(): a1} = <C<String>, int>{const C<String>(): 1};
}
