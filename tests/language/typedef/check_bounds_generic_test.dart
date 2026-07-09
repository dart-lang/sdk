// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that typedef type parameters are verified to satisfy their bounds.

typedef F<T extends num> = T Function<U>(T x);

void g(F<String>? f) {}
//     ^
// [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'F'.
//       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

main() {
  g(null);
}
