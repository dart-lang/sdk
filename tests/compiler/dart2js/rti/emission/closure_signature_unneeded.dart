// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*class: A:checks=[],instance*/
class A<T> {
  @NoInline()
  m() {
    // TODO(johnniwinther): The signature is not needed since the type isn't a
    // potential subtype of the checked function types.
    return
        /*ast.checks=[$signature],instance*/
        /*kernel.checks=[$signature],instance*/
        /*strong.checks=[],instance*/
        (T t, String s) {};
  }
}

@NoInline()
test(o) => o is void Function(int);

main() {
  test(new A<int>().m());
}
