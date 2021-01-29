// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that local boolean variables cannot be used to perform type
// promotion in the presence of compound assignments.
//
// We test the following kinds of compound assignments:
// - Ordinary (e.g. `+=`)
// - Prefix increment/decrement (e.g. `++<variable>`)
// - Postfix increment/decrement (e.g. `<variable>++`)
// - Null-aware (`??=`)
//
// We test both the side effect of the assignment and the evaluated value of the
// assignment expression.

testSideEffect(int? x) {
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b /= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b ~/= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b %= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b += x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b -= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b <<= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b >>= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b &= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b ^= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b |= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b ??= x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    ++b;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    --b;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b++;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    b--;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

testValue(int? x) {
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b /= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b ~/= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b %= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b += x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b -= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b <<= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b >>= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b &= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b ^= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b |= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b ??= x != null) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (++b) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (--b) {
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b++) {
      // Note: arguably we could promote here (since the value of `b++` is the
      // same as the value that `b` had before the "increment") but given that
      // incrementing booleans doesn't work at runtime anyhow, it doesn't seem
      // worth it.
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
    if (b--) {
      // Note: arguably we could promote here (since the value of `b--` is the
      // same as the value that `b` had before the "decrement") but given that
      // decrementing booleans doesn't work at runtime anyhow, it doesn't seem
      // worth it.
      x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int?>>();
  }
}

bool _alwaysFalse() => false;

main() {
  // Because of the use of dynamic in these tests, they're not expected to
  // succeed at runtime; we just want to check the compile-time behavior.  So we
  // reference the test functions but don't call them.
  if (_alwaysFalse()) testSideEffect(0);
  if (_alwaysFalse()) testValue(0);
}
