// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library TopLevelMultipleFilesTest.dart;

import "package:expect/expect.dart";

import 'prefixed_library.dart';

main() {
  Expect.equals(topLevelVar, 42);
  Expect.equals(topLevelMethod(), 87);
}
