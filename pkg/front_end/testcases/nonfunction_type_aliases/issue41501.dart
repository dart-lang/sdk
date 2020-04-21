// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'issue41501_lib.dart';

typedef AAliasNonNullable = A;

typedef AAliasNullable = A?;

test() {
  FutureOr<AAlias> foLegacyNonNullable = null; // error
  FutureOr<AAlias?> foLegacyNullable = null; // ok
  FutureOr<AAliasNonNullable> foNonNullable = null; // error
  FutureOr<AAliasNullable> foNullable = null; // ok
  FutureOr<AAliasNonNullable?> foNonNullableNullable = null; // ok
  FutureOr<AAliasNullable?> foNullableNullable = null; // ok
}

main() {}