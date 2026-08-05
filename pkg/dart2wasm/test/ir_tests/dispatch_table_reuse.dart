// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=runTest
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=--enable-deferred-loading

import '' deferred as D;

void main() async {
  print('main($all)');
  all.forEach((x) => x.foo(always10));
  await D.loadLibrary();
  runTest();
}

@pragma('wasm:never-inline')
void runTest() {
  final arg = always10;
  for (final object in all) {
    if (object is Sub1) {
      object.foo(arg);
    } else {
      object.foo(arg);
    }
  }
  print(D.all.toString());
}

final always10 = int.parse('10');
final all = <Base>[Base(), Sub1(), Sub2(), Sub3(), Sub4(), Sub5()];

class Base {
  void foo(int arg) {
    print('Base.foo($arg)');
  }
}

class Sub1 extends Base {
  void foo(int arg) {
    print('Sub1.foo($arg)');
    super.foo(arg);
  }

  void bar(int arg) {
    print('Sub1.bar($arg)');
  }
}

class Sub2 extends Base {
  void foo(int arg) {
    print('Sub2.foo($arg)');
    super.foo(arg);
  }
}

class Sub4 extends Base {
  void foo(int arg) {
    print('Sub4.foo($arg)');
    super.foo(arg);
  }
}

class Sub5 extends Base {
  void foo(int arg) {
    print('Sub5.foo($arg)');
    super.foo(arg);
  }
}

class Sub3 extends Base {
  void foo(int arg) {
    print('Sub3.foo($arg)');
    super.foo(arg);
  }
}
