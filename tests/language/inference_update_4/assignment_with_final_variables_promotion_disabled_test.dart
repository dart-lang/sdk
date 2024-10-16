// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests promotions with final variables are cancelled when they are
// certainly assigned when the `inference-update-4` feature flag is disabled.
// https://github.com/dart-lang/language/issues/1721

// @dart=3.6

import '../static_type_helper.dart';

isInt(bool b) {
  final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    // Promotions are cancelled because flow analysis is unsure if other
    // assignments have occurred for `x`, even though it is a final variable,
    // with the `inference-update-4` flag disabled.
    () => x.expectStaticType<Exactly<num>>();
  } else {
    () => x.expectStaticType<Exactly<num>>();
  }
}

isInt_late(bool b) {
  late final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    // Promotions are cancelled because flow analysis is unsure if other
    // assignments have occurred for `x`, even though it is a final variable,
    // with the `inference-update-4` flag disabled.
    () => x.expectStaticType<Exactly<num>>();
  } else {
    () => x.expectStaticType<Exactly<num>>();
  }
}

neqNull(bool b) {
  final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    // Promotions are cancelled because flow analysis is unsure if other
    // assignments have occurred for `x`, even though it is a final variable,
    // with the `inference-update-4` flag disabled.
    () => x.expectStaticType<Exactly<int?>>();
  } else {
    () => x.expectStaticType<Exactly<int?>>();
  }
}

neqNull_late(bool b) {
  late final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    // Promotions are cancelled because flow analysis is unsure if other
    // assignments have occurred for `x`, even though it is a final variable,
    // with the `inference-update-4` flag disabled.
    () => x.expectStaticType<Exactly<int?>>();
  } else {
    () => x.expectStaticType<Exactly<int?>>();
  }
}

main() {
  isInt(true);
  isInt(false);
  isInt_late(true);
  isInt_late(false);
  neqNull(true);
  neqNull(false);
  neqNull_late(true);
  neqNull_late(false);
}
