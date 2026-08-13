// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that match a Null scrutinee when
// `sound-flow-analysis` is enabled.

import '../static_type_helper.dart';

typedef IntQuestion = int?;

// `<pattern> as <nullable>` is known to match a null expression.
testCast({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case _ as Null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case _ as int?) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case _ as IntQuestion) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case _ as Null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case _ as int?) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case _ as IntQuestion) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case _ as Null) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case _ as int?) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <pattern> as <nullable>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case _ as IntQuestion) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nullable> <var>` is known to match a null expression.
testDeclaredVar({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case Null v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case int? v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case IntQuestion v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case Null v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case int? v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case IntQuestion v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case Null v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case int? v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> <var>
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case IntQuestion v) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nullable>()` is known to match a null expression.
testObject({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case Null()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case IntQuestion()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case Null()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case IntQuestion()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case Null()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable>()
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case IntQuestion()) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

// `<nullable> _` is known to match a null expression.
testWildcard({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case Null _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case int? _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // null case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (null case IntQuestion _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case Null _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case int? _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <var> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullValue case IntQuestion _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case Null _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case int? _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }

  {
    // <expr> case <nullable> _
    int? shouldNotBeDemoted = 0;
    int? shouldBePromoted;
    if (nullFunction() case IntQuestion _) {
      shouldBePromoted = 0; // Reachable
    } else {
      shouldNotBeDemoted = null; // Unreachable
    }
    shouldNotBeDemoted.expectStaticType<Exactly<int>>();
    shouldBePromoted.expectStaticType<Exactly<int>>();
  }
}

main() {
  testCast(nullValue: null, nullFunction: () => null);
  testDeclaredVar(nullValue: null, nullFunction: () => null);
  testObject(nullValue: null, nullFunction: () => null);
  testWildcard(nullValue: null, nullFunction: () => null);
}
