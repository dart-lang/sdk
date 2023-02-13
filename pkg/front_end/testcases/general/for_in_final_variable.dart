// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f() {
  late final i;
  for (i in [1, 2, 3]) {
    late final i2;
    i2 = 0;
  }
  final j;
  for (j in [1, 2, 3]) {
    final j2;
    j2 = 0;
  }
  for (final k in [1, 2, 3]) {
    final k2;
    k2 = 0;
  }
}

g() {
  late final i;
  final j;
  var l = [
    for (i in [1, 2, 3]) 0,
    for (j in [1, 2, 3]) 1,
    for (final k in [1, 2, 3]) 2
  ];
}
