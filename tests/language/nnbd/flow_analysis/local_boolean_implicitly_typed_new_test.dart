// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks whether a local boolean variable can be used to perform type
// promotion, if that variable is implicitly typed.
//
// This test confirms that once the "constructor tearoffs" language feature is
// enabled, initializer expressions on implicitly typed variables are no longer
// ignored for the purposes of type promotion
// (i.e. https://github.com/dart-lang/language/issues/1785 is fixed).

parameterUnmodified(int? x) {
  {
    late final b = x != null;
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
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
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
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
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
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
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    late var b = x != null;
    // We don't promote based on the initializers of late locals anyhow, because
    // we don't know when they execute.
    if (b) x.expectStaticType<Exactly<int?>>();
  }
  {
    late var b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    final b;
    b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
  }
  {
    var b = x != null;
    if (b) x.expectStaticType<Exactly<int>>();
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
