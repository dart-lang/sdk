// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  // This call is on the stack when the error is thrown.
  /*1:main*/ test();
}

@NoInline()
test() async /*2:test*/ {
  /*3:test*/ throw '>ExceptionMarker<';
}
