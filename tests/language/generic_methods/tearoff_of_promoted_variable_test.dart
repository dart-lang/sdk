// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that when tearing off a method of a promoted variable, the variable's
// promoted type is used for analysis.

import 'package:expect/expect.dart';

import '../static_type_helper.dart';

void usingExpectStaticType(num x) {
  // This is the scenario where the issue was first discovered--when using
  // `expectStaticType` and forgetting to add the `()`.
  if (x is int) {
    var f = x.expectStaticType<Exactly<int>>;
    f();
  } else {
    Expect.fail('type test should have succeeded');
  }
}

void parameter(C<num> c) {
  if (c is C<int>) {
    var f = c.func<Exactly<int>>;
    f.expectStaticType<Exactly<int Function()>>();
    var x = f();
    x.expectStaticType<Exactly<int>>();
  } else {
    Expect.fail('type test should have succeeded');
  }
}

void localVariable(C<num> value) {
  C<num> c = value;
  if (c is C<int>) {
    var f = c.func<Exactly<int>>;
    f.expectStaticType<Exactly<int Function()>>();
    var x = f();
    x.expectStaticType<Exactly<int>>();
  } else {
    Expect.fail('type test should have succeeded');
  }
}

class C<T> {
  final T t;
  C(this.t);
  T func<X extends Exactly<T>>() => t;
}

main() {
  usingExpectStaticType(0);
  parameter(C<int>(0));
  localVariable(C<int>(0));
}
