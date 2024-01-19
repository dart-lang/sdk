// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'dart:_foreign_helper' show LEGACY_TYPE_REF, TYPE_REF;
import 'dart:_runtime' show legacy, nullable;

import 'package:expect/expect.dart';

class A {}

void main() {
  // A?? == A?
  Expect.identical(nullable(TYPE_REF<A?>()), TYPE_REF<A?>());
  // A?* == A?
  Expect.identical(legacy(TYPE_REF<A?>()), TYPE_REF<A?>());
  // A*? == A?
  Expect.identical(nullable(LEGACY_TYPE_REF<A>()), TYPE_REF<A?>());
  // A** == A*
  Expect.identical(legacy(LEGACY_TYPE_REF<A>()), LEGACY_TYPE_REF<A>());

  // The tests below need explicit wrapping in nullable and legacy to ensure
  // they appear at runtime and the runtime library normalizes them correctly.
  // Null? == Null
  Expect.identical(nullable(TYPE_REF<Null>()), TYPE_REF<Null>());
  // Never? == Null
  Expect.identical(nullable(TYPE_REF<Never>()), TYPE_REF<Null>());
  // dynamic? == dynamic
  Expect.identical(nullable(TYPE_REF<dynamic>()), TYPE_REF<dynamic>());
  // void? == void
  Expect.identical(nullable(TYPE_REF<void>()), TYPE_REF<void>());
  // dynamic* == dynamic
  Expect.identical(legacy(TYPE_REF<dynamic>()), TYPE_REF<dynamic>());
  // void* == void
  Expect.identical(legacy(TYPE_REF<void>()), TYPE_REF<void>());
}
