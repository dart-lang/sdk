// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*class: A:checks=[],instance*/
class A<T> {
  instanceMethod() => A<T>;
}

/*class: B:checks=[],instance*/
class B<S, T> {
  instanceMethod<U>() => B<T, U>;
}

main() {
  var a = A<int>();
  String name1 = '${a.instanceMethod()}';
  var b = B<int, String>();
  String name2 = '${b.instanceMethod<bool>()}';

  makeLive('A<int>' == name1);
  makeLive('B<String, bool>' == name2);
}
