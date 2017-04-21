// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:expect/expect.dart';

String log;
init() {
  log = '';
}

logit(msg) {
  return log = '$log$msg';
}

class Base {
  var b;
  Base.arg0() : b = logit('b') {
    logit('B');
  }
  Base.arg1(a) : b = logit('b') {
    logit('B');
  }
  Base.arg2(a, b) : b = logit('b') {
    logit('B');
  }
}

class Sub extends Base {
  var x;
  var s;
  Sub.arg0()
      : x = logit('x'),
        super.arg0(),
        s = logit('s') {
    logit('S');
  }
  Sub.arg1(a)
      : x = logit('x'),
        super.arg1(logit('1')),
        s = logit('s') {
    logit('S');
  }
  Sub.arg2(a, b)
      : x = logit('x'),
        super.arg2(logit('1'), logit('2')),
        s = logit('s') {
    logit('S');
  }
}

test(fun(), String result) {
  init();
  fun();
  Expect.isTrue(log == result);
}

main() {
  test(() => new Sub.arg0(), 'xsbBS');
  test(() => new Sub.arg1(1), 'x1sbBS');
  test(() => new Sub.arg2(1, 2), 'x12sbBS');
}
