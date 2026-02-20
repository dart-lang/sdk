// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

import '../../static_type_helper.dart';

void context<X>(X _) {}

void main() {
  // Verify the context type via its effect on type inference.
  context<List<num>>(''.=> []..expectStaticType<Exactly<List<num>>>);
  context<Future<Pattern>>(
    ''.=> Future.value('')..expectStaticType<Exactly<Future<Pattern>>>,
  );

  // Verify that the context type can give rise to coercions.
  context<int>(''.=> 1..expectStaticType<Exactly<int>>);
  context<double>(''.=> 1..expectStaticType<Exactly<double>>);
  context<void Function(bool)>(
    ''.=> context..expectStaticType<Exactly<void Function(bool)>>,
  );
}
