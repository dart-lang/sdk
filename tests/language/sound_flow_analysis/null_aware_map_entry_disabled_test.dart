// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of null-aware map entries when `sound-flow-analysis`
// is disabled.

// @dart = 3.8

// ignore_for_file: invalid_null_aware_operator

import '../static_type_helper.dart';

// `{ ?<nonNullable>: <expr> }` is known to invoke <expr>.
// (this behavior predates sound-flow-analysis)
testNonNullable({required int intValue, required int Function() intFunction}) {
  {
    // { ?<var>: <expr> }
    int? shouldBePromoted;
    ({?intValue: shouldBePromoted = 0});
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // { ?<expr>: <expr> }
    int? shouldBePromoted;
    ({?intFunction(): shouldBePromoted = 0});
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `{ ?<Null>: <expr> }` is not known to skip <expr>.
testNull({required Null nullValue, required Null Function() nullFunction}) {
  {
    // { ?null: <expr> }
    int? shouldBeDemoted = 0;
    ({?null: (shouldBeDemoted = null, 0).$2});
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // { ?<var>: <expr> }
    int? shouldBeDemoted = 0;
    ({?nullValue: (shouldBeDemoted = null, 0).$2});
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }

  {
    // { ?<expr>: <expr> }
    int? shouldBeDemoted = 0;
    ({?nullFunction(): (shouldBeDemoted = null, 0).$2});
    shouldBeDemoted.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testNonNullable(intValue: 0, intFunction: () => 0);
  testNull(nullValue: null, nullFunction: () => null);
}
