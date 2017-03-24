// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `FutureOr<T>` is only visible when `dart:async` is imported.

dynamic foo(dynamic x) {
  return x as
      FutureOr< // //# 00: runtime error, static type warning
          int
      > //         //# 00: continued
      ;
}

main() {
  if (499 != foo(499)) throw "bad";
}
