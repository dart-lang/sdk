// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles abstract fields.

import 'package:expect/static_type_helper.dart';

abstract class C {
  abstract final int? _f1;
  abstract int? _f2;
}

class D {
  final int? _f1;
  final int? _f2;

  D(int i)
      : _f1 = i,
        _f2 = i;
}

void testAbstractFinalFieldIsPromotable(C c) {
  if (c._f1 != null) {
    c._f1.expectStaticType<Exactly<int>>();
  }
}

void testAbstractNonFinalFieldIsNotPromotable(C c) {
  // Technically, it would be sound to promote an abstract non-final field, but
  // there's no point because it's just going to be implemented by a concrete
  // non-final field or a getter/setter pair, which will prevent promotion.  So
  // we might as well prevent promotion even in the absence of an
  // implementation.
  if (c._f2 != null) {
    c._f2.expectStaticType<Exactly<int?>>();
  }
}

void testAbstractFinalFieldDoesNotBlockPromotionElsewhere(D d) {
  if (d._f1 != null) {
    d._f1.expectStaticType<Exactly<int>>();
  }
}

void testAbstractNonFinalFieldBlocksPromotionElsewhere(D d) {
  // Technically, it would be sound if an abstract non-final field didn't block
  // promotion, but there's no point because it's just going to be implemented
  // by a concrete non-final field or a getter/setter pair, which will block
  // promotion.  So we might as well block promotion even in the absence of an
  // implementation.
  if (d._f2 != null) {
    d._f2.expectStaticType<Exactly<int?>>();
  }
}

main() {}
