// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/23432.  Test that the receiver of a
// NoSuchMethodError is correct on an intercepted method.  The bug (issue 23432)
// is that the interceptor is captured instead of the receiver.

import 'package:expect/expect.dart';

class N {
  noSuchMethod(i) {
    print('x');
    return 42;
  }
}

@pragma('dart2js:noInline')
@pragma('dart2js:assumeDynamic')
get NEVER => false;

main() {
  dynamic c = 12345;
  if (NEVER) c = new N();
  var e;
  try {
    c
      ..toString()
      ..add(88);
  } catch (ex) {
    e = ex;
  }
  var s = e.toString();
  Expect.isTrue(s.contains('$c'), 'Text "$s" should contain "$c"');
}
