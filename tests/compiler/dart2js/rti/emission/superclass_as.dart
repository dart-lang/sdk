// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:meta/dart2js.dart';

/*class: A:checkedInstance,checks=[],instance*/
class A<T> {}

/*class: B:checks=[]*/
class B<T, S> {
  @noInline
  method() => new A<S>();
}

/*class: C:checks=[$asB],instance*/
class C<T> extends B<T, T> {}

@noInline
test(o) => o is A<int>;

main() {
  Expect.isTrue(test(new C<int>().method()));
  Expect.isFalse(test(new C<String>().method()));
}
