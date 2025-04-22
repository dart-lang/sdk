// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Exercises flow analysis of patterns that fail to match a Null scrutinee when
// `sound-flow-analysis` is disabled.

// @dart = 3.8

import '../static_type_helper.dart';

// `<nonNullable> <var>` is not known to mismatch a null expression.
testDeclaredVar({
  required Null nullValue,
  required Null Function() nullFunction,
}) {
  {
    // null case <nonNullable> <var>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case int i) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case <nonNullable> <var>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case int i) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case <nonNullable> <var>
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case int i) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `[...]` is not known to mismatch a null expression.
testList({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case [...]
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case [...]) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case [...]
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case [...]) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case [...]
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case [...]) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `{...}` is not known to mismatch a null expression.
testMap({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case {...}
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case {0: 0}) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case {...}
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case {0: 0}) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case {...}
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case {0: 0}) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable>()` is not known to mismatch a null expression.
testObject({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nonNullable>()
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case int()) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case <nonNullable>()
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case int()) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case <nonNullable>()
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case int()) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `(<pattern>,)` is not known to mismatch a null expression.
testRecord({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case (<pattern>,)
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case (_,)) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case (<pattern>,)
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case (_,)) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case (<pattern>,)
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case (_,)) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }
}

// `<nonNullable> _` is not known to mismatch a null expression.
testWildcard({required Null nullValue, required Null Function() nullFunction}) {
  {
    // null case <nonNullable> _
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (null case int _) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <var> case <nonNullable> _
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullValue case int _) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
  }

  {
    // <expr> case <nonNullable> _
    int? shouldBeDemoted1 = 0;
    int? shouldBeDemoted2 = 0;
    if (nullFunction() case int _) {
      shouldBeDemoted1 = null;
    } else {
      shouldBeDemoted2 = null;
    }
    shouldBeDemoted1.expectStaticType<Exactly<int?>>();
    shouldBeDemoted2.expectStaticType<Exactly<int?>>();
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
