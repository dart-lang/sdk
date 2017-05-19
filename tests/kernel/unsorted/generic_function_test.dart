// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of generic functions.

import 'package:expect/expect.dart';

typedef R Foo<R>();

bar<R>(int body()) {
  var function = () {
    if (body is Foo<R>) {
      return body();
    }
    return 42;
  };
  return function();
}

main() {
  Expect.isTrue(bar(() => 43) == 43);
}
