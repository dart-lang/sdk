// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:checks=[],instance*/
class A<T> {
  @pragma('dart2js:noInline')
  m() {
    return /*checks=[$signature],instance*/ (T t) {};
  }

  @pragma('dart2js:noInline')
  f() {
    return /*checks=[$signature],instance*/ (int t) {};
  }
}

@pragma('dart2js:noInline')
test(o) => o is void Function(int);

main() {
  test(new A<int>().m());
  test(new A<int>().f());
}
