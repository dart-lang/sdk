// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:core" as T;

class C<T> {
  T.String method() => "Hello, World!";
}

main() {
  T.String s = new C().method();
  T.print(s);
}
