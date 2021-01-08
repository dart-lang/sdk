// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test verifies that when control flow paths are joined, flow analysis
// does not recognize and coalesce distinct but equivalent assignments of test
// expressions to a boolean.  So for example, even though this promotes:
//
//   bool b;
//   b = x != null;
//   if (b) { /* x is promoted to non-nullable */ }
//
// This does not:
//
//   bool b;
//   if (...) {
//     b = x != null;
//   } else {
//     b = x != null;
//   }
//   if (b) { /* x is not promoted */ }
//
// We test all flow control constructs where a join might occur, including:
// - At the end of an if/else construct or conditional expression
// - At the end of a loop where the "break" control flow path joins the main
//   control flow path
// - At the point in a "do" or "for" loop where the "continue" control flow path
//   joins the main control flow path
// - Inside a loop where multiple "break" or "continue" paths are implicitly
//   joined
// - Inside a switch statement where multiple "break" paths are implicitly
//   joined
// - At the end of an exhaustive switch statement where the last case is
//   implicitly joined to the "break" path
// - After a "catch" where the main control flow path is resumed
// - After a labeled statement where the "break" control flow path is joined to
//   the main control flow path

enum E { E1, E2 }

bool _alwaysFalse(dynamic d) => false;

dynamic _alwaysThrow(dynamic d) {
  throw 'foo';
}

test(int? x, bool b1, E e) {
  {
    bool b2;
    b1
        ? [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
        : [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null];
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    if (b1) {
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    } else {
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    [
      if (b1)
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
      else
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
    ];
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    ({
      if (b1)
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
      else
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
    });
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    ({
      if (b1)
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]: null
      else
        [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]: null
    });
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    ({
      if (b1)
        null: [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
      else
        null: [b2 = x != null, b2 ? x.expectStaticType<Exactly<int>>() : null]
    });
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    do {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      }
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    } while (false);
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2 = false;
    for (int i = 0; i < 1; i++) {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      }
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2 = false;
    int i = 0;
    while (i < 1) {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      }
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
      i++;
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    do {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        continue;
      }
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    } while (_alwaysFalse(b2 ? x.expectStaticType<Exactly<int?>>() : null));
  }
  {
    try {
      bool b2;
      for (;; _alwaysThrow(b2 ? x.expectStaticType<Exactly<int?>>() : null)) {
        if (b1) {
          b2 = x != null;
          if (b2) x.expectStaticType<Exactly<int>>();
          continue;
        }
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
      }
    } catch (_) {}
  }
  {
    bool b2;
    while (true) {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      } else {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      }
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    do {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        continue;
      } else {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        continue;
      }
    } while (_alwaysFalse(b2 ? x.expectStaticType<Exactly<int?>>() : null));
  }
  {
    bool b2;
    switch (e) {
      case E.E1:
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      case E.E2:
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    switch (e) {
      case E.E1:
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break;
      case E.E2:
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    try {
      if (b1) throw 'foo';
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    } catch (_) {
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
  {
    bool b2;
    label:
    {
      if (b1) {
        b2 = x != null;
        if (b2) x.expectStaticType<Exactly<int>>();
        break label;
      }
      b2 = x != null;
      if (b2) x.expectStaticType<Exactly<int>>();
    }
    if (b2) x.expectStaticType<Exactly<int?>>();
  }
}

main() {
  test(null, false, E.E1);
  test(null, true, E.E2);
  test(1, false, E.E1);
  test(1, true, E.E2);
}
