// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:checkedTypeArgument,checks=[],typeArgument*/
class A {}

/*class: B:checks=[],typeArgument*/
class B {}

/*class: C:checkedInstance,checks=[],instance*/
class C<T> {}

@noInline
test(o) => o is C<A>;

main() {
  test(new C<A>());
  test(new C<B>());
}
