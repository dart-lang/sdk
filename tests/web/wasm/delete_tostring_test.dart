// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final _one = int.parse('1');
final _two = int.parse('2');

final message1 = 'foo';
final message2 = 'bar';

final _objects = [
  Object(),
  ExpectException(message1),
  ExpectException(message2),
];

final first = _objects[_one];
final second = _objects[_two];

main() {
  // We get the normal `ExpectException.toString()`
  Expect.equals(message1, first.toString());
  Expect.equals(message2, second.toString());
}
