// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  try {
    print('hello1');
  } catch (e, _) {} finally {
    print('hello2');
  }
  print('hello3');
  print(foo());
  print(bar());
}

int foo() {
  try {
    print('foo 1');
    return 1;
  } catch (e, _) {} finally {
    print('foo 2');
    return 2;
  }
}

int bar() {
  try {
    print('bar 1');
    return 1;
  } catch (e, _) {} finally {
    print('bar 2');
  }
  return 0;
}
