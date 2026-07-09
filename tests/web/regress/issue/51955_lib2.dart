// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String work() {
  final list = [for (int i = 0; i < 10; i++) (1, i, i * i)];
  return list
      .reduce((a, b) => (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3))
      .toString();
}
