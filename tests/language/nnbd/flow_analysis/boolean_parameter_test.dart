// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks whether a function parameter can be used to perform type
// promotion, for various ways of declaring it.
//
// We test all combinations of:
// - top level function, method, local named function, or function expression
// - type `bool`, `Object`, `Object?`, or `dynamic`

topLevelFunction_bool(int? x, bool b) {
  b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
}

topLevelFunction_Object(int? x, Object b) {
  b = x != null;
  // We don't currently recognize that `b as bool` has the same value as `b`,
  // so we don't promote.  TODO(paulberry): should we?
  if (b as bool) x.expectStaticType<Exactly<int?>>();
}

topLevelFunction_ObjectQ(int? x, Object? b) {
  b = x != null;
  // We don't currently recognize that `b as bool` has the same value as `b`,
  // so we don't promote.  TODO(paulberry): should we?
  if (b as bool) x.expectStaticType<Exactly<int?>>();
}

topLevelFunction_dynamic(int? x, dynamic b) {
  b = x != null;
  if (b) x.expectStaticType<Exactly<int>>();
}

class C {
  method_bool(int? x, bool b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }

  method_Object(int? x, Object b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }

  method_ObjectQ(int? x, Object? b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }

  method_dynamic(int? x, dynamic b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

localTest(int? x) {
  localNamedFunction_bool(bool b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }

  localNamedFunction_bool(false);

  localNamedFunction_Object(Object b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }

  localNamedFunction_Object(Object());

  localNamedFunction_ObjectQ(Object? b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }

  localNamedFunction_ObjectQ(null);

  localNamedFunction_dynamic(dynamic b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }

  localNamedFunction_dynamic('foo');

  (bool b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }(false);

  (Object b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }(Object());

  (Object? b) {
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }(null);

  (dynamic b) {
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }('foo');
}

main() {
  topLevelFunction_bool(null, false);
  topLevelFunction_bool(0, false);
  topLevelFunction_Object(null, Object());
  topLevelFunction_Object(0, Object());
  topLevelFunction_ObjectQ(null, null);
  topLevelFunction_ObjectQ(0, null);
  topLevelFunction_dynamic(null, 'foo');
  topLevelFunction_dynamic(0, 'foo');
  C().method_bool(null, false);
  C().method_bool(0, false);
  C().method_Object(null, Object());
  C().method_Object(0, Object());
  C().method_ObjectQ(null, null);
  C().method_ObjectQ(0, null);
  C().method_dynamic(null, 'foo');
  C().method_dynamic(0, 'foo');
  localTest(null);
  localTest(0);
}
