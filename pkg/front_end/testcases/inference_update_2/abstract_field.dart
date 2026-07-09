// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles abstract fields.

abstract class C {
  abstract final int? _f1;
  abstract int? _f2;
}

class D {
  final int? _f1;
  final int? _f2;

  D(int i) : _f1 = i, _f2 = i;
}

void acceptsInt(int x) {}

void testAbstractFinalFieldIsPromotable(C c) {
  if (c._f1 != null) {
    var x = c._f1;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testAbstractNonFinalFieldIsNotPromotable(C c) {
  // Technically, it would be sound to promote an abstract non-final field, but
  // there's no point because it's just going to be implemented by a concrete
  // non-final field or a getter/setter pair, which will prevent promotion.  So
  // we might as well prevent promotion even in the absence of an
  // implementation.
  if (c._f2 != null) {
    var x = c._f2;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

void testAbstractFinalFieldDoesNotBlockPromotionElsewhere(D d) {
  if (d._f1 != null) {
    var x = d._f1;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testAbstractNonFinalFieldBlocksPromotionElsewhere(D d) {
  // Technically, it would be sound if an abstract non-final field didn't block
  // promotion, but there's no point because it's just going to be implemented
  // by a concrete non-final field or a getter/setter pair, which will block
  // promotion.  So we might as well block promotion even in the absence of an
  // implementation.
  if (d._f2 != null) {
    var x = d._f2;
    // `x` has type `int?` so this is ok
    x = null;
  }
}

main() {}
