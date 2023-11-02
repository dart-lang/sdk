// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

main() {
  T id<T>(T t) => t;
  int Function(int) x = id;
  var toString = "${x.runtimeType}";
  if (!toString.contains('minified:')) {
    // The signature of `id` is not otherwise needed so the instantiation
    // wrapper doesn't have a function type.
    // The type parameter is present since it is required because `==`
    // distinguishes instantiations of the same generic function with different
    // types.
    Expect.equals("Instantiation1<int>", toString);
  }
  print(toString);
}
