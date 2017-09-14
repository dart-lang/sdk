// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Foo {
  var field = 10;
}

@NoInline()
getField(x) {
  x.field;
  return 34;
}

main() {
  Expect.equals(34, getField(new Foo()));
  Expect.throws(() => getField(null));
}
