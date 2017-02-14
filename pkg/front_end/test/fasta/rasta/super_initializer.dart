// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Super {
  Super.arg0();
  Super.arg1(a);
  Super.arg2(a, b);
}

class Sub extends Super {
  var field;
  Sub.arg0() : super.arg0(), field = 42;
  Sub.arg1(a) : super.arg1(a), field = 42;
  Sub.arg2(a, b) : super.arg2(a, b), field = 42;
}
