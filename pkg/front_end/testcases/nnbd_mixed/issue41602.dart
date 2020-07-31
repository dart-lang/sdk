// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

Future<void> returnFutureOfVoid() async {}

void returnVoid() {}

void returnVoidAsync() async {}

main() async {
  await returnVoid(); // ok since this library is opted out.
  await returnFutureOfVoid(); // ok
  await returnVoidAsync(); // ok since this library is opted out.
}
