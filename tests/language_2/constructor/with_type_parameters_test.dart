// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bar<T> {
  Bar() {} //# 01: ok
  Bar.boo() {} //# 02: ok
  Bar<E>() {} //# 03: compile-time error
  Bar<E>.boo() {} //# 04: syntax error
  Bar.boo<E>() {} //# 05: syntax error
  Bar.boo<E>.baz() {} //# 06: syntax error

  Bar(); //# 07: ok
  Bar.boo(); //# 08: ok
  Bar<E>(); //# 09: compile-time error
  Bar<E>.boo(); //# 10: syntax error
  Bar.boo<E>(); //# 11: syntax error
  Bar.boo<E>.baz(); //# 12: syntax error

  const Bar(); //# 13: ok
  const Bar.boo(); //# 14: ok
  const Bar<E>(); //# 15: syntax error
  const Bar<E>.boo(); //# 16: syntax error
  const Bar.boo<E>(); //# 17: syntax error
  const Bar.boo<E>.baz(); //# 18: syntax error
}

main() {}
