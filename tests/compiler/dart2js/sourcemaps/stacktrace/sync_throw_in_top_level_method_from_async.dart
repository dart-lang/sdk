// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  /*1:main*/ test1();
}

@NoInline()
test1() async /*2:test1*/ /*kernel.3:test1*/ {
  /*9:test1*/ test2();
}

@NoInline()
test2() {
  /*10:test2*/ throw '>ExceptionMarker<';
}
