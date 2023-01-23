// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test(dynamic x) {
  if (x case var y as int) {
    return 0;
  }
  if (x case [var y as String]) {
    return 1;
  }
  if (x case [[var y] as List<bool>, 0]) {
    return 2;
  }
  if (x case 1 as int) {
    return 3;
  }
  if (x case var _ as String) {
    return 4;
  }
}
