// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/507666702.
//
// Verifies that non-linear subtype test cache can handle instantiated generic closures.

import "package:expect/expect.dart";

final log = StringBuffer();
final map = <String, String>{};

String foo<T>() {
  log.write('foo<$T>');
  return 'foo';
}

const foo1 = foo<int>;
const foo2 = foo<String>;

void main() {
  // Fill subtype test cache of 'putIfAbsent' arguments so
  // it switches from linear to hash.
  map.putIfAbsent('1', ({int? a1}) => '');
  map.putIfAbsent('2', ({int? a2}) => '');
  map.putIfAbsent('3', ({int? a3}) => '');
  map.putIfAbsent('4', ({int? a4}) => '');
  map.putIfAbsent('5', ({int? a5}) => '');
  map.putIfAbsent('6', ({int? a6}) => '');
  map.putIfAbsent('7', ({int? a7}) => '');
  map.putIfAbsent('8', ({int? a8}) => '');
  map.putIfAbsent('9', ({int? a9}) => '');
  map.putIfAbsent('10', ({int? a10}) => '');
  map.putIfAbsent('11', ({int? a11}) => '');
  map.putIfAbsent('12', ({int? a12}) => '');
  map.putIfAbsent('13', ({int? a13}) => '');
  map.putIfAbsent('14', ({int? a14}) => '');
  map.putIfAbsent('15', ({int? a15}) => '');
  map.putIfAbsent('16', ({int? a16}) => '');
  map.putIfAbsent('17', ({int? a17}) => '');
  map.putIfAbsent('18', ({int? a18}) => '');
  map.putIfAbsent('19', ({int? a19}) => '');
  map.putIfAbsent('20', ({int? a20}) => '');
  map.putIfAbsent('21', ({int? a21}) => '');
  map.putIfAbsent('22', ({int? a22}) => '');
  map.putIfAbsent('23', ({int? a23}) => '');
  map.putIfAbsent('24', ({int? a24}) => '');
  map.putIfAbsent('25', ({int? a25}) => '');
  map.putIfAbsent('26', ({int? a26}) => '');
  map.putIfAbsent('27', ({int? a27}) => '');
  map.putIfAbsent('28', ({int? a28}) => '');
  map.putIfAbsent('29', ({int? a29}) => '');
  map.putIfAbsent('30', ({int? a30}) => '');
  map.putIfAbsent('31', ({int? a31}) => '');
  map.putIfAbsent('32', ({int? a32}) => '');
  // Test hash-based STC with instantiated generic closures.
  for (int i = 0; i < 5; ++i) {
    map.putIfAbsent('foo1', foo1);
  }
  for (int i = 0; i < 5; ++i) {
    map.putIfAbsent('foo2', foo2);
  }
  Expect.equals('foo<int>foo<String>', log.toString());
}
