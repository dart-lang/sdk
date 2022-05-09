// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var list = [1]
    ..add(2)
    ..add(3)
    ..addAll([4, 5]);
  print(list);

  list
    ..add(2)
    ..length
    ..length = 0;
  print(list);

  list
    ..add(2)
    ..[0]
    ..[0] = 87;

  print(list);

  list = [
    [1]
  ]
    ..first.last.toString()
    ..first[0].toString()
    ..[0].last.toString();

  print(list);
}
