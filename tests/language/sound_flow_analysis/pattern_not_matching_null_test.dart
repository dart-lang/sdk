// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that fail to match a Null scrutinee when
// `sound-flow-analysis` is enabled.

// SharedOptions=--enable-experiment=sound-flow-analysis

import '../static_type_helper.dart';

// `<nonNullable> <var>` is known to mismatch a null expression.
testDeclaredVar({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null case <nonNullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case int i) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nonNullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case int i) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nonNullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case int i) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `[...]` is known to mismatch a null expression.
testList({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case [...]
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case [...]) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case [...]
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case [...]) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case [...]
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case [...]) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `{...}` is known to mismatch a null expression.
testMap({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case {...}
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case {0: 0}) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case {...}
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case {0: 0}) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case {...}
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case {0: 0}) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable>()` is known to mismatch a null expression.
testObject({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nonNullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case int()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nonNullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case int()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nonNullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case int()) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `(<pattern>,)` is known to mismatch a null expression.
testRecord({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case (<pattern>,)
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case (_,)) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case (<pattern>,)
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case (_,)) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case (<pattern>,)
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case (_,)) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nonNullable> _` is known to mismatch a null expression.
testWildcard({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nonNullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case int _) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nonNullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case int _) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nonNullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case int _) {
      shouldNotBeDemoted = null; // Unreachable
    } else {
      shouldBePromoted = 0; // Reachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testDeclaredVar(nullValue: null, nullFunction: () => null);
  testList(nullValue: null, nullFunction: () => null);
  testMap(nullValue: null, nullFunction: () => null);
  testObject(nullValue: null, nullFunction: () => null);
  testRecord(nullValue: null, nullFunction: () => null);
  testWildcard(nullValue: null, nullFunction: () => null);
}
