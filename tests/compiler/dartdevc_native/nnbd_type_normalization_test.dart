// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'dart:_runtime' show legacy, nullable, typeRep, legacyTypeRep;

import 'package:expect/expect.dart';

class A {}

void main() {
  // A?? == A?
  Expect.identical(nullable(typeRep<A?>()), typeRep<A?>());
  // A?* == A?
  Expect.identical(legacy(typeRep<A?>()), typeRep<A?>());
  // A*? == A?
  Expect.identical(nullable(legacyTypeRep<A>()), typeRep<A?>());
  // A** == A*
  Expect.identical(legacy(legacyTypeRep<A>()), legacyTypeRep<A>());

  // The tests below need explicit wrapping in nullable and legacy to ensure
  // they appear at runtime and the runtime library normalizes them correctly.
  // Null? == Null
  Expect.identical(nullable(typeRep<Null>()), typeRep<Null>());
  // Never? == Null
  Expect.identical(nullable(typeRep<Never>()), typeRep<Null>());
  // dynamic? == dynamic
  Expect.identical(nullable(typeRep<dynamic>()), typeRep<dynamic>());
  // void? == void
  Expect.identical(nullable(typeRep<void>()), typeRep<void>());
  // dynamic* == dynamic
  Expect.identical(legacy(typeRep<dynamic>()), typeRep<dynamic>());
  // void* == void
  Expect.identical(legacy(typeRep<void>()), typeRep<void>());
}
