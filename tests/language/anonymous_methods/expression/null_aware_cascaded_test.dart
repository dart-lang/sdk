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
    final v1 = buffer?..=> foo;
    final v2 = (buffer?..=> foo)?..=> foo;
    final v3 = (buffer?..=> foo)?.=> foo;
    final v4 = (buffer?.=> foo.orNull)?..=> foo;
    final v5 = buffer?..=> foo..=> foo;
    final v6 = buffer?..=> (foo?..=> foo);
    final v7 = buffer?..=> foo.=> foo;
    final v8 = buffer?.=> foo?..=> foo;
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
    final v1 = buffer?..=> this.length;
    final v2 = (buffer?..=> this.length)?..=> this.length.isEven ? 'true' : '';
    final v3 = buffer?..=> this == buffer..=> this.length;
    final v4 = buffer?..=> this == (buffer?..=> this.length);
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
    final v1 = buffer?..=> length;
    final v2 = (buffer?..=> length)?..=> length.isEven ? 'true' : '';
    final v3 = buffer?..=> length..=> length;
    final v4 = buffer?..=> (length.orNull?..=> isEven);
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
    final v1 = buffer?..(p) => p.length;
    final v2 = (buffer?..(p) => p == buffer)?..(p) => p == buffer ? 'true' : '';
    final v3 = (buffer?..(p) => p == buffer)?..(q) => q == buffer ? 'true' : '';
    final v4 = buffer?..(p) => p == buffer..(p) => p.length;
    final v5 = buffer?..(p) => p == (buffer?..(p) => p.length);
    final v6 = buffer?..(p) => p == (buffer?..(q) => p.length);
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
    final v1 = buffer?..(StringBuffer p) => p.length;
    final v2 = (buffer?..(Object? p) => p == buffer)
        ?..(StringBuffer p) => p.isEmpty ? 'true' : '';
    final v3 = (buffer?..(Object p) => p == buffer)
        ?..(StringBuffer q) => q.isEmpty ? 'true' : '';
    final v4 = buffer?..(Object p) => p == 1..(StringBuffer p) => p.length;
    final v5 = buffer?..(Object p) => p == (1?..(int p) => p.isEven);
    final v6 = buffer?..(StringBuffer p) => p == (1?..(q) => p.length);
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
  final aThenBIgnoringBody = a?.b?..=> hasDays() ? days : null;
  aThenBIgnoringBody.expectStaticType<Exactly<B?>>;
}
