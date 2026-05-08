// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods using null-aware, cascaded accesses.
// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';
import '../../static_type_helper.dart';

StringBuffer? buffer = StringBuffer(''); // `length` remains 0.
StringBuffer? notBuffer = null;
int foo = 42;
int? notFoo = null;

extension<X extends Object> on X {
  X? get orNull => this;
}

class A {
  B? get b => B();
}

class B {
  bool hasDays() => true;
  int get days => 1;
}

A? a = A();

void main() {
  // No dependency on `this` or parameters.
  {
    final v1 = buffer?..{
      return foo;
    };

    final v2 = (buffer?..{
      return foo;
    })?..{
      return foo;
    };

    final v3 = (buffer?..{
      return foo;
    })?.{
      return foo;
    };

    final v4 = (buffer?.{
      return foo.orNull;
    })?..{
      return foo;
    };

    final v5 = buffer?..{
      return foo..{
        return foo;
      };
    };

    final v6 = buffer?..{
      return foo?..{
        return foo;
      };
    };

    final v7 = buffer?..{
      return foo.{
        return foo;
      };
    };

    final v8 = buffer?.{
      return foo?..{
        return foo;
      };
    };

    v1.expectStaticType<Exactly<StringBuffer?>>;
    v2.expectStaticType<Exactly<StringBuffer?>>;
    v3.expectStaticType<Exactly<int?>>;
    v4.expectStaticType<Exactly<int?>>;
    v5.expectStaticType<Exactly<StringBuffer?>>;
    v6.expectStaticType<Exactly<StringBuffer?>>;
    v7.expectStaticType<Exactly<StringBuffer?>>;
    v8.expectStaticType<Exactly<int?>>;
    Expect.equals(buffer, v1);
    Expect.equals(buffer, v2);
    Expect.equals(foo, v3);
    Expect.equals(foo, v4);
    Expect.equals(buffer, v5);
    Expect.equals(buffer, v6);
    Expect.equals(buffer, v7);
    Expect.equals(foo, v8);
  }

  // Dependency on `this`.
  {
    final v1 = buffer?..{
      return this.length;
    };

    final v2 = (buffer?..{
      return this.length;
    })?..{
      return this.length.isEven ? 'true' : '';
    };

    final v3 = buffer?..{
      return this == buffer;
    }..{
      return this.length;
    };

    final v4 = buffer?..{
      return this == (buffer?..{
        return this.length;
      });
    };

    v1.expectStaticType<Exactly<StringBuffer?>>;
    v2.expectStaticType<Exactly<StringBuffer?>>;
    v3.expectStaticType<Exactly<StringBuffer?>>;
    v4.expectStaticType<Exactly<StringBuffer?>>;
    Expect.equals(buffer, v1);
    Expect.equals(buffer, v2);
    Expect.equals(buffer, v3);
    Expect.equals(buffer, v4);
  }

  // Dependency on implicit `this`.
  {
    final v1 = buffer?..{
      return length;
    };

    final v2 = (buffer?..{
      return length;
    })?..{
      return length.isEven ? 'true' : '';
    };

    final v3 = buffer?..{
      return length;
    }..{
      return length;
    };

    final v4 = buffer?..{
      return length.orNull?..{
        return isEven;
      };
    };

    v1.expectStaticType<Exactly<StringBuffer?>>;
    v2.expectStaticType<Exactly<StringBuffer?>>;
    v3.expectStaticType<Exactly<StringBuffer?>>;
    v4.expectStaticType<Exactly<StringBuffer?>>;
    Expect.equals(buffer, v1);
    Expect.equals(buffer, v2);
    Expect.equals(buffer, v3);
    Expect.equals(buffer, v4);
  }

  // Dependency on parameter.
  {
    final v1 = buffer?..(p) {
      return p.length;
    };

    final v2 = (buffer?..(p) {
      return p == buffer;
    })?..(p) {
      return p == buffer ? 'true' : '';
    };

    final v3 = (buffer?..(p) {
      return p == buffer;
    })?..(q) {
      return q == buffer ? 'true' : '';
    };

    final v4 = buffer?..(p) {
      return p == buffer;
    }..(p) {
      return p.length;
    };

    final v5 = buffer?..(p) {
      return p == (buffer?..(p) {
        return p.length;
      });
    };

    final v6 = buffer?..(p) {
      return p == (buffer?..(q) {
        return p.length;
      });
    };

    v1.expectStaticType<Exactly<StringBuffer?>>;
    v2.expectStaticType<Exactly<StringBuffer?>>;
    v3.expectStaticType<Exactly<StringBuffer?>>;
    v4.expectStaticType<Exactly<StringBuffer?>>;
    v5.expectStaticType<Exactly<StringBuffer?>>;
    v6.expectStaticType<Exactly<StringBuffer?>>;
    Expect.equals(buffer, v1);
    Expect.equals(buffer, v2);
    Expect.equals(buffer, v3);
    Expect.equals(buffer, v4);
    Expect.equals(buffer, v5);
    Expect.equals(buffer, v6);
  }

  // Dependency on parameter with type annotation.
  {
    final v1 = buffer?..(StringBuffer p) {
      return p.length;
    };

    final v2 = (buffer?..(Object? p) {
      return p == buffer;
    })?..(StringBuffer p) {
      return p.isEmpty ? 'true' : '';
    };

    final v3 = (buffer?..(Object p) {
      return p == buffer;
    })?..(StringBuffer q) {
      return q.isEmpty ? 'true' : '';
    };

    final v4 = buffer?..(Object p) {
      return p == 1;
    }..(StringBuffer p) {
      return p.length;
    };

    final v5 = buffer?..(Object p) {
      return p == (1?..(int p) {
          return p.isEven;
      });
    };

    final v6 = buffer?..(StringBuffer p) {
      return p == (1?..(q) {
          return p.length;
      });
    };

    v1.expectStaticType<Exactly<StringBuffer?>>;
    v2.expectStaticType<Exactly<StringBuffer?>>;
    v3.expectStaticType<Exactly<StringBuffer?>>;
    v4.expectStaticType<Exactly<StringBuffer?>>;
    v5.expectStaticType<Exactly<StringBuffer?>>;
    v6.expectStaticType<Exactly<StringBuffer?>>;
    Expect.equals(buffer, v1);
    Expect.equals(buffer, v2);
    Expect.equals(buffer, v3);
    Expect.equals(buffer, v4);
    Expect.equals(buffer, v5);
    Expect.equals(buffer, v6);
  }

  // Example using two kinds of null aware access.
  final aThenBIgnoringBody = a?.b?..{
    return hasDays() ? days : null;
  };
  aThenBIgnoringBody.expectStaticType<Exactly<B?>>;
}
