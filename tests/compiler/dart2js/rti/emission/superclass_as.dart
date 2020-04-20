// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*class: A:checkedInstance,checks=[],instance*/
class A<T> {}

/*class: B:checks=[],indirectInstance*/
class B<T, S> {
  @pragma('dart2js:noInline')
  method() => new A<S>();
}

/*class: C:checks=[],instance*/
class C<T> extends B<T, T> {}

@pragma('dart2js:noInline')
test(o) => o is A<int>;

main() {
  Expect.isTrue(test(new C<int>().method()));
  Expect.isFalse(test(new C<String>().method()));
}
