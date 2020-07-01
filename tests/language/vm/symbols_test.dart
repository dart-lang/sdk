// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  print(const Symbol(null));                                //# 01: compile-time error
  print(const Symbol(r''));                                 //# 02: ok
  Expect.isTrue(identical(const Symbol(r'foo'), #foo));     //# 03: ok
  Expect.isTrue(identical(const Symbol(r'$foo'), #$foo));   //# 03: ok
  Expect.isTrue(identical(const Symbol(r'$_'), #$_));       //# 03: ok
  Expect.isTrue(identical(const Symbol(r'+'), #+));         //# 03: ok
  Expect.isTrue(identical(const Symbol(r'[]='), #[]=));     //# 03: ok
  Expect.isTrue(identical(const Symbol(r'_foo'), #_foo));   //# 03: compile-time error
  Expect.isTrue(identical(const Symbol(r'_$'), #_$));       //# 03: compile-time error
  Expect.isTrue(identical(const Symbol(r'_foo$'), #_foo$)); //# 03: compile-time error
  print(const Symbol(r'_+'));                               //# 03: compile-time error
}
