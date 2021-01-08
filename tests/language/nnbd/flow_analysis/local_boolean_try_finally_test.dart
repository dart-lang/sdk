// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that a local boolean condition variable can be used for
// promotion in various corner case scenarios involving try/finally statements.

test(int? x, bool b2) {
  {
    bool b = b2;
    try {
      b = x != null;
      if (b) x.expectStaticType<Exactly<int>>();
    } finally {
      if (b) x.expectStaticType<Exactly<int?>>();
    }
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    try {
      b = x != null;
      if (b) x.expectStaticType<Exactly<int>>();
    } finally {
      // Note: we can't do `if (b)` here because `b` is not definitely assigned.
    }
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b = b2;
    try {
      if (b) x.expectStaticType<Exactly<int?>>();
    } finally {
      b = x != null;
      if (b) x.expectStaticType<Exactly<int>>();
    }
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    try {
      // Note: we can't do `if (b)` here because `b` is not definitely assigned.
    } finally {
      b = x != null;
      if (b) x.expectStaticType<Exactly<int>>();
    }
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

main() {
  test(null, false);
  test(null, true);
  test(0, false);
  test(0, true);
}
