// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of null-aware map entries when `sound-flow-analysis`
// is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

// ignore_for_file: invalid_null_aware_operator

import '../static_type_helper.dart';

// `{ ?<nonNullable>: <expr> }` is known to invoke <expr>.
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

// `{ ?<Null>: <expr> }` is known to skip <expr>.
testNull({required Null nullValue, required Null Function() nullFunction}) {
  {
    // { ?null: <expr> }
    int? shouldNotBeDemoted = 0;
    ({?null: (shouldNotBeDemoted = null, 0).$2});
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // { ?<var>: <expr> }
    int? shouldNotBeDemoted = 0;
    ({?nullValue: (shouldNotBeDemoted = null, 0).$2});
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }

  {
    // { ?<expr>: <expr> }
    int? shouldNotBeDemoted = 0;
    ({?nullFunction(): (shouldNotBeDemoted = null, 0).$2});
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testNonNullable(intValue: 0, intFunction: () => 0);
  testNull(nullValue: null, nullFunction: () => null);
}
