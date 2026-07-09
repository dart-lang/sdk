// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Separate test for int64 support to be skipped on the web.

import 'iterable_return_type_helper.dart';

import 'dart:collection';
import 'dart:typed_data';

main() {
  // Types for int64 support
  testList(new Uint64List(1)..[0] = 1);
  testList(new Int64List(1)..[0] = 1);
}
