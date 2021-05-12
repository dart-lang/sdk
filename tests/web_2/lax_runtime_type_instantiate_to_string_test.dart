// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// dart2jsOptions=--strong --omit-implicit-checks --lax-runtime-type-to-string

import 'package:expect/expect.dart';

main() {
  T id<T>(T t) => t;
  int Function(int) x = id;
  var toString = "${x.runtimeType}";
  if ('$Object' == 'Object') {
    // `true` if non-minified.
    // The signature of `id` is not otherwise needed so the instantiation
    // wrapper doesn't have a function type.
    Expect.equals("Instantiation1<dynamic>", toString);
  }
  print(toString);
}
