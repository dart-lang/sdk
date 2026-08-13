// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method(List list) {
  for (var [a, b] = list; a < 10; a++) {
    print('$a, $b');
  }
  for (var [a, b] in list) {
    print('$a, $b');
  }
}
