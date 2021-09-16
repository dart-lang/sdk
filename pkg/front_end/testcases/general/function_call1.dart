// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Closure1 {
  _Closure1 get call => this;
}

class _Closure2 {
  final _Closure2 call;

  _Closure2(this.call);
}

test(_Closure1 foo, _Closure2 bar) {
  foo();
  bar();
}

late _Closure1 closure1;
late _Closure2 closure2;

var field1 = closure1();
var field2 = closure2();

main() {}
