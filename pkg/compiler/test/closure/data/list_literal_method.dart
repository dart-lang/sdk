// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

@pragma('dart2js:noInline')
method<T>() {
  /*fields=[T],free=[T]*/ dynamic local() => <T>[];
  return local;
}

@pragma('dart2js:noInline')
methodNullable<T>() {
  /*fields=[T],free=[T]*/ dynamic local() => <T?>[];
  return local;
}

@pragma('dart2js:noInline')
test(o) => o is List<int>;

@pragma('dart2js:noInline')
testNullable(o) => o is List<int?>;

main() {
  Expect.isTrue(test(method<int>().call()));
  Expect.isTrue(testNullable(methodNullable<int>().call()));
  Expect.isFalse(test(method<String>().call()));
}
