// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "dart:async";
import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/41465

void main() {
  var stream = Stream.fromIterable([1, 2, 3, 4]);
  var eventsStream =
      stream.asyncMap((i) => i % 2 == 0 ? i : null).where((i) => i != null);
  eventsStream.listen(Expect.isNotNull);
}
