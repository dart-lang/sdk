// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

library opted_out_lib;

import 'dart:async';
import 'issue41501.dart';

class A {}

typedef AAlias = A;

test() {
  FutureOr<AAlias> foLegacy = null; // ok
  FutureOr<AAliasNonNullable> foNonNullable = null; // ok
  FutureOr<AAliasNullable> foNullable = null; // ok
}

