// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  test1();
}

@NoInline()
test1() async {
  await null;
  /*1:test1*/ test2();
}

@NoInline()
test2() {
  /*2:test2*/ throw '>ExceptionMarker<';
}
