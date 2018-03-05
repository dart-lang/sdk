// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  noSuchMethod(Invocation invocation) {
    var s = '|${invocation.memberName}|';
    for (var a in invocation.positionalArguments) {
      s = '$s$a|';
    }
    invocation.namedArguments.forEach((Symbol k, v) {
      s = '$s$k/$v|';
    });
    print(s);
    return s;
  }
}

main() {
  dynamic o = new A();
  Expect.isTrue(o.fun() == '|${#fun}|');
  Expect.isTrue(o.fun(1) == '|${#fun}|1|');
  Expect.isTrue(o.fun(1, 2) == '|${#fun}|1|2|');
  Expect.isTrue(o.fun(1, b: 2) == '|${#fun}|1|${#b}/2|');
  Expect.isTrue(o.fun(1, a: 1, b: 2) == '|${#fun}|1|${#a}/1|${#b}/2|');
  Expect.isTrue(o.fun(1, b: 2, a: 1) == '|${#fun}|1|${#a}/1|${#b}/2|');
}
