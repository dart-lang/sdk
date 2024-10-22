// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the behavior described in
// https://github.com/dart-lang/language/issues/4127 has been fixed. That is,
// when deciding whether an `==` or `!=` comparison is guaranteed to evaluate to
// `true` or `false`, flow analysis considers promoted fields to have their
// promoted type.

// This test acts as a regression test for #4127.

import '../static_type_helper.dart';

class C {
  final Object? _f;
  C(this._f);

  void testImplicitThisReferenceOnLhsOfEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_f is! Null) return;
    _f.expectStaticType<Exactly<Null>>();
    if (_f == null) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `==` check, flow analysis assumes that `_f` has its
    // promoted type (`Null`), so only the `x = null` branch is
    // reachable. Therefore only `x` should be demoted here.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void testImplicitThisReferenceOnRhsOfEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_f is! Null) return;
    _f.expectStaticType<Exactly<Null>>();
    if (null == _f) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `==` check, flow analysis assumes that `_f` has its
    // promoted type (`Null`), so only the `x = null` branch is
    // reachable. Therefore only `x` should be demoted here.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void testImplicitThisReferenceOnLhsOfNotEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_f is! Null) return;
    _f.expectStaticType<Exactly<Null>>();
    if (_f != null) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `!=` check, flow analysis assumes that `_f` has its
    // promoted type (`Null`), so only the `y = null` branch is
    // reachable. Therefore only `y` should be demoted here.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void testImplicitThisReferenceOnRhsOfNotEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (_f is! Null) return;
    _f.expectStaticType<Exactly<Null>>();
    if (null != _f) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `!=` check, flow analysis assumes that `_f` has its
    // promoted type (`Null`), so only the `y = null` branch is
    // reachable. Therefore only `y` should be demoted here.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void testExplicitThisReferenceOnLhsOfEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._f is! Null) return;
    this._f.expectStaticType<Exactly<Null>>();
    if (this._f == null) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `==` check, flow analysis assumes that `this._f` has its
    // promoted type (`Null`), so only the `x = null` branch is
    // reachable. Therefore only `x` should be demoted here.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void testExplicitThisReferenceOnRhsOfEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._f is! Null) return;
    this._f.expectStaticType<Exactly<Null>>();
    if (null == this._f) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `==` check, flow analysis assumes that `this._f` has its
    // promoted type (`Null`), so only the `x = null` branch is
    // reachable. Therefore only `x` should be demoted here.
    x.expectStaticType<Exactly<int?>>();
    y.expectStaticType<Exactly<int>>();
  }

  void testExplicitThisReferenceOnLhsOfNotEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._f is! Null) return;
    this._f.expectStaticType<Exactly<Null>>();
    if (this._f != null) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `!=` check, flow analysis assumes that `this._f` has its
    // promoted type (`Null`), so only the `y = null` branch is
    // reachable. Therefore only `y` should be demoted here.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int?>>();
  }

  void testExplicitThisReferenceOnRhsOfNotEquals() {
    int? x = 0;
    int? y = 0;
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int>>();
    if (this._f is! Null) return;
    this._f.expectStaticType<Exactly<Null>>();
    if (null != this._f) {
      x = null;
    } else {
      y = null;
    }
    // In analyzing the `!=` check, flow analysis assumes that `this._f` has its
    // promoted type (`Null`), so only the `y = null` branch is
    // reachable. Therefore only `y` should be demoted here.
    x.expectStaticType<Exactly<int>>();
    y.expectStaticType<Exactly<int?>>();
  }
}

void testExplicitPropertyReferenceOnLhsOfEquals(C c) {
  int? x = 0;
  int? y = 0;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._f is! Null) return;
  c._f.expectStaticType<Exactly<Null>>();
  if (c._f == null) {
    x = null;
  } else {
    y = null;
  }
  // In analyzing the `==` check, flow analysis assumes that `c._f` has its
  // promoted type (`Null`), so only the `x = null` branch is
  // reachable. Therefore only `x` should be demoted here.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int>>();
}

void testExplicitPropertyReferenceOnRhsOfEquals(C c) {
  int? x = 0;
  int? y = 0;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._f is! Null) return;
  c._f.expectStaticType<Exactly<Null>>();
  if (null == c._f) {
    x = null;
  } else {
    y = null;
  }
  // In analyzing the `==` check, flow analysis assumes that `c._f` has its
  // promoted type (`Null`), so only the `x = null` branch is
  // reachable. Therefore only `x` should be demoted here.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int>>();
}

void testExplicitPropertyReferenceOnLhsOfNotEquals(C c) {
  int? x = 0;
  int? y = 0;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._f is! Null) return;
  c._f.expectStaticType<Exactly<Null>>();
  if (c._f != null) {
    x = null;
  } else {
    y = null;
  }
  // In analyzing the `!=` check, flow analysis assumes that `c._f` has its
  // promoted type (`Null`), so only the `y = null` branch is
  // reachable. Therefore only `y` should be demoted here.
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int?>>();
}

void testExplicitPropertyReferenceOnRhsOfNotEquals(C c) {
  int? x = 0;
  int? y = 0;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._f is! Null) return;
  c._f.expectStaticType<Exactly<Null>>();
  if (null != c._f) {
    x = null;
  } else {
    y = null;
  }
  // In analyzing the `!=` check, flow analysis assumes that `c._f` has its
  // promoted type (`Null`), so only the `y = null` branch is
  // reachable. Therefore only `y` should be demoted here.
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int?>>();
}

main() {
  for (var value in [null, '']) {
    var c = C(value);
    c.testImplicitThisReferenceOnLhsOfEquals();
    c.testImplicitThisReferenceOnRhsOfEquals();
    c.testImplicitThisReferenceOnLhsOfNotEquals();
    c.testImplicitThisReferenceOnRhsOfNotEquals();
    c.testExplicitThisReferenceOnLhsOfEquals();
    c.testExplicitThisReferenceOnRhsOfEquals();
    c.testExplicitThisReferenceOnLhsOfNotEquals();
    c.testExplicitThisReferenceOnRhsOfNotEquals();
    testExplicitPropertyReferenceOnLhsOfEquals(c);
    testExplicitPropertyReferenceOnRhsOfEquals(c);
    testExplicitPropertyReferenceOnLhsOfNotEquals(c);
    testExplicitPropertyReferenceOnRhsOfNotEquals(c);
  }
}
