// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

var x = 'a';

Future<int> foo() async {
  return x; /*@compile-error=unspecified*/
}

main() {
  foo();
}
