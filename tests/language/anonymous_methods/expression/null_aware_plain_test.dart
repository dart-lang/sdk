// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods using null-aware accesses.
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
    final v1 = buffer?.=> foo;
    final v2 = (buffer?.=> foo)?.=> foo;
    final v3 = buffer?.=> foo.orNull?.=> foo;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<int?>>;
    v3.expectStaticType<Exactly<int?>>;
    Expect.equals(foo, v1);
    Expect.equals(foo, v2);
    Expect.equals(foo, v3);
  }

  // No dependency on `this` or parameters, condition fails.
  {
    final v1 = notBuffer?.=> foo;
    final v2 = (notBuffer?.=> foo)?.=> foo;
    final v3 = (buffer?.=> notFoo)?.=> foo;
    final v4 = notBuffer?.=> foo.orNull?.=> foo;
    final v5 = buffer?.=> notFoo?.=> foo;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<int?>>;
    v3.expectStaticType<Exactly<int?>>;
    v4.expectStaticType<Exactly<int?>>;
    v5.expectStaticType<Exactly<int?>>;
    Expect.equals(null, v1);
    Expect.equals(null, v2);
    Expect.equals(null, v3);
    Expect.equals(null, v4);
    Expect.equals(null, v5);
  }

  // Dependency on `this`.
  {
    final v1 = buffer?.=> this.length;
    final v2 = (buffer?.=> this.length)?.=> this.isEven ? 'true' : '';
    final v3 = buffer?.=> this.length == buffer?.=> this.length;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<String?>>;
    v3.expectStaticType<Exactly<bool?>>;
    Expect.equals(buffer?.length, v1);
    Expect.equals('true', v2);
    Expect.equals(true, v3);
  }

  // Dependency on implicit `this`.
  {
    final v1 = buffer?.=> length;
    final v2 = (buffer?.=> length)?.=> isEven ? 'true' : '';
    final v3 = buffer?.=> length.orNull?.=> isEven;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<String?>>;
    v3.expectStaticType<Exactly<bool?>>;
    Expect.equals(buffer?.length, v1);
    Expect.equals('true', v2);
    Expect.equals(false, v3);
  }

  // Dependency on parameter.
  {
    final v1 = buffer?.(p) => p.length;
    final v2 = (buffer?.(p) => p == buffer)?.(p) => p ? 'true' : '';
    final v3 = (buffer?.(p) => p == buffer)?.(q) => q ? 'true' : '';
    final v4 = buffer?.(p) => p == buffer?.(p) => p.length;
    final v5 = buffer?.(p) => p == buffer?.(q) => p.length;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<String?>>;
    v3.expectStaticType<Exactly<String?>>;
    v4.expectStaticType<Exactly<bool?>>;
    v5.expectStaticType<Exactly<bool?>>;
    Expect.equals(buffer?.length, v1);
    Expect.equals('true', v2);
    Expect.equals('true', v3);
    Expect.equals(false, v4);
    Expect.equals(false, v5);
  }

  // Dependency on parameter with type annotation.
  {
    final v1 = buffer?.(StringBuffer p) => p.length;
    final v2 = (buffer?.(Object? p) => p == buffer)
        ?.(bool p) => p ? 'true' : '';
    final v3 = (buffer?.(Object p) => p == buffer)?.(bool q) => q ? 'true' : '';
    final v4 = buffer?.(Object p) => p == buffer?.(StringBuffer p) => p.length;
    final v5 = buffer?.(StringBuffer p) => p == buffer?.(q) => p.length;
    v1.expectStaticType<Exactly<int?>>;
    v2.expectStaticType<Exactly<String?>>;
    v3.expectStaticType<Exactly<String?>>;
    v4.expectStaticType<Exactly<bool?>>;
    v5.expectStaticType<Exactly<bool?>>;
    Expect.equals(buffer?.length, v1);
    Expect.equals('true', v2);
    Expect.equals('true', v3);
    Expect.equals(false, v4);
    Expect.equals(false, v5);
  }

  // Example using two kinds of null aware access.
  int? daysOfAThenB = a?.b?.=> hasDays() ? days : null;
  Expect.equals(1, daysOfAThenB);
}
