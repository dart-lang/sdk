// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library named_constructor_test;

import 'package:expect/expect.dart';
import 'named_constructor_lib.dart' as prefix;

class Class<T> {
  final int value;
  Class() : value = 0;
  Class.named() : value = 1;
}

void main() {
  Expect.equals(0, new Class().value);
  Expect.equals(0, new Class<int>().value);

  Expect.equals(1, new Class.named().value);
  Expect.equals(1, new Class<int>.named().value);
  // 'Class.named' is not a type:
  Expect.equals(1, new Class.named<int>().value); //# 01: runtime error
  // 'Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(1, new Class<int>.named<int>().value); //# 02: syntax error

  Expect.equals(2, new prefix.Class().value);
  // 'prefix' is not a type:
  Expect.equals(2, new prefix<int>.Class().value); //# 03: runtime error
  Expect.equals(2, new prefix.Class<int>().value);
  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(2, new prefix<int>.Class<int>().value); //# 04: syntax error

  Expect.equals(3, new prefix.Class.named().value);
  // 'prefix<int>.Class.named' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix<int>.Class.named().value); //# 05: syntax error
  // 'prefix.Class<int>.named' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix.Class<int>.named().value);
  // 'prefix.Class.named<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix.Class.named<int>().value); //# 06: syntax error
  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix<int>.Class<int>.named().value); //# 07: syntax error
  // 'prefix<int>.Class.named<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix<int>.Class.named<int>().value); //# 08: syntax error
  // 'prefix.Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix.Class<int>.named<int>().value); //# 09: syntax error
  // 'prefix<int>.Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  Expect.equals(3, new prefix<int>.Class<int>.named<int>().value); //# 10: syntax error
}
