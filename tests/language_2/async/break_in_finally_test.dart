// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

then43() async {
  label:
  try {
    return await 42;
  } finally {
    break label;
  }
  return await 43;
}

then42() async {
  label:
  try {
    return await 42;
  } finally {}
  return await 43;
}

now43() {
  label:
  try {
    return 42;
  } finally {
    break label;
  }
  return 43;
}

now42() {
  label:
  try {
    return 42;
  } finally {}
  return 43;
}

test() async {
  Expect.equals(42, await then42());
  Expect.equals(43, await then43());
  Expect.equals(42, now42());
  Expect.equals(43, now43());
}

main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
