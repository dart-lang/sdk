// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks whether a local boolean variable can be used to perform type
// promotion, for various ways of declaring and assigning to it.
//
// For the boolean, we test all combinations of:
// - type `bool`, `Object`, `Object?`, or `dynamic`
// - late or non-late
// - final or non-final
// - assigned at initialization time or later
// For the promoted variable, we test all combinations of:
// - parameter, unmodified from its initial value
// - parameter, assigned later
// - local variable, assigned at initialization
// - local variable, assigned later

parameterUnmodified(int? x) {
  {
    late final bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late final Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

parameterModifiedLater(int? x, int? y) {
  x = y;
  {
    late final bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late final Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

localVariableInitialized(int? y) {
  int? x = y;
  {
    late final bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late final Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

localVariableModifiedLater(int? y) {
  int? x;
  x = y;
  {
    late final bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late bool b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late bool b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    bool b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late final Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    final Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    Object? b;
    b = x != null;
    // We don't currently recognize that `b as bool` has the same value as `b`,
    // so we don't promote.  TODO(paulberry): should we?
    if (b as bool) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late dynamic b = x != null;
    // We don't promote based on the initializers of late locals because we
    // don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late dynamic b;
    b = x != null;
    // We do promote based on assignments to late locals because we do know when
    // they execute.
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    dynamic b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

main() {
  parameterUnmodified(null);
  parameterUnmodified(0);
  parameterModifiedLater(null, null);
  parameterModifiedLater(null, 0);
  localVariableInitialized(null);
  localVariableInitialized(0);
  localVariableModifiedLater(null);
  localVariableModifiedLater(0);
}
