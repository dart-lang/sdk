// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  print(const Symbol(null)); //# 01: compile-time error
  print(const Symbol(r''));
  Expect.isTrue(identical(const Symbol(r'foo'), #foo));
  Expect.isTrue(identical(const Symbol(r'$foo'), #$foo));
  Expect.isTrue(identical(const Symbol(r'$_'), #$_));
  Expect.isTrue(identical(const Symbol(r'+'), #+));
  Expect.isTrue(identical(const Symbol(r'[]='), #[]=));
  Expect.isFalse(identical(const Symbol(r'_foo'), #_foo));
  Expect.isFalse(identical(const Symbol(r'_$'), #_$));
  Expect.isFalse(identical(const Symbol(r'_foo$'), #_foo$));
  print(const Symbol(r'_+'));
}
