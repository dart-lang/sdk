// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library named_constructor_test;

import 'package:expect/expect.dart';
import 'named_lib.dart' as prefix;

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

  // 'Class<int>.named<int>' doesn't fit the grammar syntax T.id:


  new prefix.Class().value;
  // 'prefix' is not a type:

  new prefix.Class<int>().value;
  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:


  new prefix.Class.named().value;
  // 'prefix<int>.Class.named' doesn't fit the grammar syntax T.id:

  // 'prefix.Class<int>.named' doesn't fit the grammar syntax T.id:
  new prefix.Class<int>.named().value;
  // 'prefix.Class.named<int>' doesn't fit the grammar syntax T.id:

  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:

  // 'prefix<int>.Class.named<int>' doesn't fit the grammar syntax T.id:

  // 'prefix.Class<int>.named<int>' doesn't fit the grammar syntax T.id:

  // 'prefix<int>.Class<int>.named<int>' doesn't fit the grammar syntax T.id:

}
