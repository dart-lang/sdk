// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  // Keep `count` in the compiled method, then verify `for-in` uses its default.
  final direct = Range(3);
  Expect.isTrue(direct.moveNext(2));
  Expect.equals(1, direct.current);

  Expect.listEquals([0, 1, 2], consume(Range(3)));
}

final class Range extends Iterable<int> implements Iterator<int> {
  Range(this.length);

  final int length;
  int _current = -1;

  @override
  int get current => _current;

  @override
  Range get iterator => Range(length);

  @override
  bool moveNext([int count = 1]) {
    _current += count;
    return _current < length;
  }
}

@pragma('dart2js:noInline')
List<int> consume(Iterable<int> values) {
  final result = <int>[];
  for (final value in values) {
    result.add(value);
  }
  return result;
}
