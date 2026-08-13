// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test() {
  var list = [
    DateTime.now().add(Duration(days: 3)),
    DateTime.now().add(Duration(days: 2)),
    DateTime.now(),
    DateTime.now().subtract(Duration(days: 1))
  ];

  list.sort((a, b) => a.compareTo(b));
  print(list);

  print(DateTime.parse(2019-01-17 00:00:00.000));
}

main() {}