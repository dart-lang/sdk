// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

use(o) {}

void Function() f(List<int> list) {
  return switch (list) {
    [final item] => () {
        use(item);
      },
    [...] => () {},
  };
}
