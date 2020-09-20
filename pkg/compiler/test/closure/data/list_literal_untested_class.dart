// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

/*member: A.:hasThis*/
class A<T> {
  /*member: A.method:hasThis*/
  @pragma('dart2js:noInline')
  method() {
    /*spec.fields=[this],free=[this],hasThis*/
    /*prod.hasThis*/
    dynamic local() => <T>[];
    return local;
  }
}

@pragma('dart2js:noInline')
test(o) => o == null;

main() {
  Expect.isTrue(test(new A<int>().method().call()));
  Expect.isTrue(test(new A<String>().method().call()));
  Expect.isFalse(test(null));
}
