// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:checks=[]*/
class A<T> {}

/*class: B:checks=[$asA]*/
class B<S, T> extends A<T> {} // Non-trivial substitution of A.

/*class: C:checks=[$isA]*/
class C<T> implements B<T, T> {} // Trivial substitution of A

@noInline
test(o) => o is A<String>;

main() {
  test(new C<String>());
  test(new B<String, int>());
}
