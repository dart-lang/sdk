// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests interactions between field promotion and try/finally statements.

// In a try/finally statement, the `finally` clause is analyzed as though the
// `try` block hasn't executed yet (and any variables written inside the `try`
// block have been de-promoted), to account for the fact that an exception might
// occur at any time during the `try` block. However, after the `finally` block
// is finished, any flow model changes that occurred during the `finally` block
// are rewound and re-applied to the flow model state after the `try` block, to
// account for the fact that if the try/finally statement completes normally, it
// is known that the `try` block executed fully.
//
// We need to verify that this rebasing logic handles all the possible ways that
// field promotion can occur relative to a try/finally statement.

import '../static_type_helper.dart';

class C {
  final Object? _o1;
  C(this._o1);
}

class D {
  final C _c;
  final Object? _o2;
  D(this._c, this._o2);
}

abstract class E {
  C get _c;
  Object? get _o3;
}

class F extends E {
  final C _c;
  final Object? _o3;
  F(this._c, this._o3);
}

void promotedInTry(D d) {
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void promotedBeforeTryFinally(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  d._c._o1!;
  d._o2!;
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void promotedBeforeTryFinallyAndInTry(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  d._c._o1!;
  d._o2!;
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
    d._c._o1 as int;
    d._o2 as int;
    d._c._o1.expectStaticType<Exactly<int>>();
    d._o2.expectStaticType<Exactly<int>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<int>>();
  d._o2.expectStaticType<Exactly<int>>();
}

void promotedInBothTryAndFinally_sameType(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void promotedInBothTryAndFinally_finallyTypeIsSubtype(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1 as int;
    d._o2 as int;
    d._c._o1.expectStaticType<Exactly<int>>();
    d._o2.expectStaticType<Exactly<int>>();
  }
  d._c._o1.expectStaticType<Exactly<int>>();
  d._o2.expectStaticType<Exactly<int>>();
}

void promotedInBothTryAndFinally_finallyTypeIsSupertype(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1 as int;
    d._o2 as int;
    d._c._o1.expectStaticType<Exactly<int>>();
    d._o2.expectStaticType<Exactly<int>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<int>>();
  d._o2.expectStaticType<Exactly<int>>();
}

void promotedInFinally(D d) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void promotedBeforeTryFinally_assignedInTry(D d, D d2) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  d._c._o1!;
  d._o2!;
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
    d = d2;
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  }
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
}

void promotedBeforeTryFinally_assignedAndRepromotedInTry(D d, D d2) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  d._c._o1!;
  d._o2!;
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
    d = d2;
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void assignedInTry_promotedInFinally(D d, D d2) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d = d2;
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
  } finally {
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void assignedInTry_promotedInFinally_propertyUnknownInTry(D d, D d2) {
  try {
    // Note: no calls to `expectStaticType` here, because we want to trigger the
    // code path where flow analysis doesn't even know about the property until
    // the finally block
    d = d2;
  } finally {
    d._c._o1!;
    d._o2!;
    d._c._o1.expectStaticType<Exactly<Object>>();
    d._o2.expectStaticType<Exactly<Object>>();
  }
  d._c._o1.expectStaticType<Exactly<Object>>();
  d._o2.expectStaticType<Exactly<Object>>();
}

void notPromotableInTry_promotedInFinally(E e) {
  try {
    e._c._o1!;
    e._o3!;
    e._c._o1.expectStaticType<Exactly<Object?>>();
    e._o3.expectStaticType<Exactly<Object?>>();
  } finally {
    e as F;
    e._c._o1!;
    e._o3!;
    e._c._o1.expectStaticType<Exactly<Object>>();
    e._o3.expectStaticType<Exactly<Object>>();
  }
  e._c._o1.expectStaticType<Exactly<Object>>();
  e._o3.expectStaticType<Exactly<Object>>();
}

void assignedButNotPromotableInTry_promotedInFinally(E e, E e2) {
  try {
    e = e2;
    e._c._o1!;
    e._o3!;
    e._c._o1.expectStaticType<Exactly<Object?>>();
    e._o3.expectStaticType<Exactly<Object?>>();
  } finally {
    e as F;
    e._c._o1!;
    e._o3!;
    e._c._o1.expectStaticType<Exactly<Object>>();
    e._o3.expectStaticType<Exactly<Object>>();
  }
  e._c._o1.expectStaticType<Exactly<Object>>();
  e._o3.expectStaticType<Exactly<Object>>();
}

void assignedAndPromotedInTry_promotedToSubtypeInFinally(D d, D d2) {
  d._c._o1.expectStaticType<Exactly<Object?>>();
  d._o2.expectStaticType<Exactly<Object?>>();
  try {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d = d2;
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1 as num;
    d._o2 as num;
    d._c._o1.expectStaticType<Exactly<num>>();
    d._o2.expectStaticType<Exactly<num>>();
  } finally {
    d._c._o1.expectStaticType<Exactly<Object?>>();
    d._o2.expectStaticType<Exactly<Object?>>();
    d._c._o1 as int;
    d._o2 as int;
    d._c._o1.expectStaticType<Exactly<int>>();
    d._o2.expectStaticType<Exactly<int>>();
  }
  d._c._o1.expectStaticType<Exactly<int>>();
  d._o2.expectStaticType<Exactly<int>>();
}

main() {
  C c = C(1);
  D d = D(c, 2);
  F f = F(c, 3);
  promotedInTry(d);
  promotedBeforeTryFinally(d);
  promotedBeforeTryFinallyAndInTry(d);
  promotedInBothTryAndFinally_sameType(d);
  promotedInBothTryAndFinally_finallyTypeIsSubtype(d);
  promotedInBothTryAndFinally_finallyTypeIsSupertype(d);
  promotedInFinally(d);
  promotedBeforeTryFinally_assignedInTry(d, d);
  promotedBeforeTryFinally_assignedAndRepromotedInTry(d, d);
  assignedInTry_promotedInFinally(d, d);
  assignedInTry_promotedInFinally_propertyUnknownInTry(d, d);
  notPromotableInTry_promotedInFinally(f);
  assignedButNotPromotableInTry_promotedInFinally(f, f);
  assignedAndPromotedInTry_promotedToSubtypeInFinally(d, d);
}
