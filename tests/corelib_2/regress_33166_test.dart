// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/33166
void main() async {
  var stream = new Stream.fromIterable([1, 2, 3]);
  Expect.equals(await stream.cast<int>().drain().then((_) => 'Done'), 'Done');
}
