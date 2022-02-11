// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

enum Enum1 { a, b, c }

typedef Alias1 = Enum1;

test() {
  Enum1(123, 'foo');
  Enum2(123, 'foo');
  Alias1(123, 'foo');
  Alias2(123, 'foo');
}

main() {}
