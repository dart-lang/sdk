// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/*element: A.:hasThis*/
class A<T> {
  /*element: A.method:hasThis*/
  @NoInline()
  method() {
    /*fields=[this],free=[this],hasThis*/ dynamic local() => <T>[];
    return local;
  }
}

@NoInline()
test(o) => o is List<int>;

main() {
  Expect.isTrue(test(new A<int>().method().call()));
  Expect.isFalse(test(new A<String>().method().call()));
}
