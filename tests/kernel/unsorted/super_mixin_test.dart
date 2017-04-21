// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Base {
  var field;

  method(x) {
    print(x);
    return x;
  }

  set setter(x) {
    print(x);
    field = x;
  }
}

class Mixin {
  method(x) {
    return super.method(x + 'Mixin');
  }

  set setter(x) {
    super.setter = x + 'Mixin';
  }
}

class Sub extends Base with Mixin {}

main() {
  var object = new Sub();
  Expect.isTrue(object.method('x') == 'xMixin');
  object.setter = 'y';
  Expect.isTrue(object.field == 'yMixin');
}
