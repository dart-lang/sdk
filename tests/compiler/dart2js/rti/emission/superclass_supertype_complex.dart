// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/dart2js.dart';

/*class: A:checkedTypeArgument,checks=[],typeArgument*/
class A<T> {}

/*class: B:checkedInstance*/
class B<T> {}

/*class: C:checks=[],indirectInstance*/
class C<T> {}

/*class: D:checks=[$asB,$isB],instance*/
class D<T> extends C<T> implements B<A<T>> {}

@noInline
test(o) => o is B<A<String>>;

main() {
  test(new D<String>());
  test(new D<int>());
}
