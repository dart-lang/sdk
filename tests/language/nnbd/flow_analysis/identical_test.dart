// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';
import 'dart:core' as core;

import 'package:expect/static_type_helper.dart';

// This test verifies that `identical` is treated the same as `==` by flow
// analysis.

void testUnprefixed(int? i) {
  i.expectStaticType<Exactly<int?>>;
  if (!identical(i, null)) {
    i.expectStaticType<Exactly<int>>;
  }
  i.expectStaticType<Exactly<int?>>;
  if (!identical(null, i)) {
    i.expectStaticType<Exactly<int>>;
  }
  i.expectStaticType<Exactly<int?>>;
}

void testPrefixed(int? i) {
  i.expectStaticType<Exactly<int?>>;
  if (!core.identical(i, null)) {
    i.expectStaticType<Exactly<int>>;
  }
  i.expectStaticType<Exactly<int?>>;
  if (!core.identical(null, i)) {
    i.expectStaticType<Exactly<int>>;
  }
  i.expectStaticType<Exactly<int?>>;
}

main() {
  testUnprefixed(null);
  testUnprefixed(0);
  testPrefixed(null);
  testPrefixed(0);
}
