// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*class: A:checks=[],instance*/
class A<T> {
  @pragma('dart2js:noInline')
  m() {
    // TODO(johnniwinther): The signature is not needed since the type isn't a
    // potential subtype of the checked function types.
    return

        /*checks=[$signature],instance*/
        (T t, String s) {};
  }
}

@pragma('dart2js:noInline')
test(o) => o is void Function(int);

main() {
  test(new A<int>().m());
}
