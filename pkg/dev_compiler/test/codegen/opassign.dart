// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

get index {
  print('called "index" getter');
  return 0;
}

final _foo = new Foo();
get foo {
  print('called "foo" getter');
  return _foo;
}

class Foo { int x = 100; }

main() {
  var f = { 0: 40 };
  print('should only call "index" 2 times:');
  ++f[index];
  forcePostfix(f[index]++);

  print('should only call "foo" 2 times:');
  ++foo.x;
  forcePostfix(foo.x++);

  print('op assign test, should only call "index" twice:');
  f[index] += f[index];
}

// Postfix generates as prefix if the value isn't used. This method prevents it.
forcePostfix(x) {}
