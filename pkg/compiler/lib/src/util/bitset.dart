// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

extension type const Bitset(int bits) {
  const Bitset.empty() : this(0);

  @useResult
  Bitset intersection(Bitset other) => Bitset(bits & other.bits);

  @useResult
  Bitset union(Bitset other) => Bitset(bits | other.bits);

  @useResult
  Bitset setMinus(Bitset other) => Bitset(bits & ~other.bits);

  bool intersects(Bitset other) => bits & other.bits != 0;

  bool get isEmpty => bits == 0;

  bool get isNotEmpty => bits != 0;
}
