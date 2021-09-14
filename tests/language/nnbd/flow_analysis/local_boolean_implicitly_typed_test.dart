// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.13

import '../../static_type_helper.dart';

// This test checks whether a local boolean variable can be used to perform type
// promotion, if that variable is implicitly typed.
//
// Due to https://github.com/dart-lang/language/issues/1785, initializer
// expressions on implicitly typed variables are ignored for the purposes of
// type promotion (however, later assignments to those variables still do
// influence promotion).  To avoid introducing breaking language changes, we
// intend to preserve this behavior until a specific Dart language version.
// This test verifies that for code that is not opted in to the newer behavior,
// the old (buggy) behavior persists.

parameterUnmodified(int? x) {
  {
    late final b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

parameterModifiedLater(int? x, int? y) {
  x = y;
  {
    late final b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

localVariableInitialized(int? y) {
  int? x = y;
  {
    late final b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
}

localVariableModifiedLater(int? y) {
  int? x;
  x = y;
  {
    late final b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We wouldn't promote based on the initializers of late locals anyhow,
    // because we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    var b;
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
