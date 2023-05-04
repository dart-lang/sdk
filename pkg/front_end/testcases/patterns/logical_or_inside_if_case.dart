// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  if (x case int? _ || double? _) {}
}

test2(dynamic x) {
  if (x case [int y, var _] || [var _, String y]) { // Error
    return y;
  } else {
    return null;
  }
}

test3(dynamic x) {
  if (x case == 1 || == 2 || == 3) {
    return 0;
  } else {
    return 1;
  }
}

test4(dynamic x) {
  if (x case [int y, var _, _] || [var _, String y, _] || [var _, bool y, _]) {
    return y;
  } else {
    return null;
  }
}

