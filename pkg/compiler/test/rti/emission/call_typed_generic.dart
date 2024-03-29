// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/util/testing.dart';

/*class: A:checks=[],instance*/
class A<T> {
  call(T t) {}
}

@pragma('dart2js:noInline')
test(o) => o is Function(int);

main() {
  makeLive(test(new A<int>()));
  makeLive(test(new A<String>()));
}
