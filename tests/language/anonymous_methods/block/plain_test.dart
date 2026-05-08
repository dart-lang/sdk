// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods using plain accesses.
// SharedOptions=--enable-experiment=anonymous-methods

import 'package:expect/expect.dart';
import '../../static_type_helper.dart';

StringBuffer buffer = StringBuffer(''); // `length` remains 0.
int foo = 42;

void main() {
  // No dependency on `this` or parameters.
  {
    final v1 = buffer.{
      return foo;
    };

    final v2 = (buffer.{
      return foo;
    }).{
      return foo;
    };

    final v3 = buffer.{
      return foo.{
        return foo;
      };
    };

    v1.expectStaticType<Exactly<int>>;
    v2.expectStaticType<Exactly<int>>;
    v3.expectStaticType<Exactly<int>>;
    Expect.equals(foo, v1);
    Expect.equals(foo, v2);
    Expect.equals(foo, v3);
  }

  // Dependency on `this`.
  {
    final v1 = buffer.{
      return this.length;
    };

    final v2 = (buffer.{
      return this == buffer;
    }).{
      return this ? 'true' : '';
    };

    final v3 = buffer.{
      return this.length == buffer.{
        return this.length;
      };
    };

    v1.expectStaticType<Exactly<int>>;
    v2.expectStaticType<Exactly<String>>;
    v3.expectStaticType<Exactly<bool>>;
    Expect.equals(buffer.length, v1);
    Expect.equals('true', v2);
    Expect.equals(true, v3);
  }

  // Dependency on implicit `this`.
  {
    final v1 = buffer.{
      return length;
    };

    final v2 = (buffer.{
      return length;
    }).{
      return isEven ? 'true' : '';
    };

    final v3 = buffer.{
      return true ^ length.{
        return isEven;
      };
    };

    v1.expectStaticType<Exactly<int>>;
    v2.expectStaticType<Exactly<String>>;
    v3.expectStaticType<Exactly<bool>>;
    Expect.equals(buffer.length, v1);
    Expect.equals('true', v2);
    Expect.equals(false, v3);
  }

  // Dependency on parameter.
  {
    final v1 = buffer.(p) {
      return p.length;
    };

    final v2 = (buffer.(p) {
      return p == buffer;
    }).(p) {
      return p ? 'true' : '';
    };

    final v3 = (buffer.(p) {
      return p == buffer;
    }).(q) {
      return q ? 'true' : '';
    };

    final v4 = buffer.(p) {
      return p == buffer.(p) {
        return p.length;
      };
    };

    final v5 = buffer.(p) {
      return p == buffer.(q) {
        return p.length;
      };
    };

    v1.expectStaticType<Exactly<int>>;
    v2.expectStaticType<Exactly<String>>;
    v3.expectStaticType<Exactly<String>>;
    v4.expectStaticType<Exactly<bool>>;
    v5.expectStaticType<Exactly<bool>>;
    Expect.equals(buffer.length, v1);
    Expect.equals('true', v2);
    Expect.equals('true', v3);
    Expect.equals(false, v4);
    Expect.equals(false, v5);
  }

  // Dependency on parameter with type annotation.
  {
    final v1 = buffer.(StringBuffer p) {
      return p.length;
    };

    final v2 = (buffer.(Object? p) {
      return p == buffer;
    }).(bool p) {
      return p ? 'true' : '';
    };

    final v3 = (buffer.(Object p) {
      return p == buffer;
    }).(bool q) {
      return q ? 'true' : '';
    };

    final v4 = buffer.(Object p) {
      return p == buffer.(StringBuffer p) {
        return p.length;
      };
    };

    final v5 = buffer.(StringBuffer p) {
      return p == buffer.(q) {
        return p.length;
      };
    };

    v1.expectStaticType<Exactly<int>>;
    v2.expectStaticType<Exactly<String>>;
    v3.expectStaticType<Exactly<String>>;
    v4.expectStaticType<Exactly<bool>>;
    v5.expectStaticType<Exactly<bool>>;
    Expect.equals(buffer.length, v1);
    Expect.equals('true', v2);
    Expect.equals('true', v3);
    Expect.equals(false, v4);
    Expect.equals(false, v5);
  }
}
