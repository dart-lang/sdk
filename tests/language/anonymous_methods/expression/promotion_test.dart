// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

import '../../static_type_helper.dart';

final String receiver = '';
final String? maybeReceiver = receiver;

void main() {
  // Promotion in an anonymous method body succeeds.
  {
    Object o = 1;
    receiver.=> o as int;
    o.expectStaticType<Exactly<int>>;
  }

  // Ditto, cascaded.
  {
    Object o = 1;
    receiver..=> o as int;
    o.expectStaticType<Exactly<int>>;
  }

  // Promotion in a null-aware anonymous method body does not survive.
  {
    Object o = 1;
    maybeReceiver?.=> o as int;
    o.expectStaticType<Exactly<Object>>;
  }

  // Ditto, cascaded.
  {
    Object o = 1;
    maybeReceiver?..=> o as int;
    o.expectStaticType<Exactly<Object>>;
  }

  // Assignment in an anonymous method body does not make the variable
  // non-promotable, null-aware/cascaded or not.
  {
    Object o = 1;
    receiver.=> (o = true, o = 2);
    receiver..=> (o = true, o = 2);
    maybeReceiver?.=> (o = true, o = 2);
    maybeReceiver?..=> (o = true, o = 2);
    if (o is int) {
      o.expectStaticType<Exactly<int>>;
    }
  }

  // Propagate promotion from one anonymous method to the next.
  {
    Object o1 = 1, o2 = 2, o3 = 3, o4 = 4;
    (receiver.=> o1 as int).=> o1.isEven;
    (maybeReceiver?.=> o2 as int?)?.=>
        o2.expectStaticType<Exactly<Object>>;
    ((receiver.=> o3 as num).=> o3 as int).=> o3.isEven;
    ((maybeReceiver?.=> o4 as num?)?.=> o4 as int?)?.=>
        o4.expectStaticType<Exactly<Object>>;
  }

  // Ditto, cascaded.
  {
    Object o1 = 1, o2 = 2, o3 = 3, o4 = 4;
    receiver
      ..=> o1 as int
      ..=> o1.isEven;
    maybeReceiver
      ?..=> o2 as int
      ..=> o2.isEven;
    receiver
      ..=> o3 as num
      ..=> o3 as int
      ..=> o3.isEven;
    maybeReceiver
      ?..=> o4 as num
      ..=> o4 as int
      ..=> o4.isEven;
  }
}
