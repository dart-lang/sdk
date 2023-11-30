// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'mixin_break_mixin_class.dart';

const LINE_B2 = 11;

class Hello2 with HelloMixin {
  void speak() {
    sayHello(); // LINE_B2
    print(' - Hello2');
  }
}
