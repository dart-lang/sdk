// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void foo() {}

main() {
  final dynamic tearoff = foo;

  Expect.throwsNoSuchMethodError(() {
    tearoff<String>(3);
  }, 'Providing type arguments to a non-generic tearoff should throw go NSM.');
}
