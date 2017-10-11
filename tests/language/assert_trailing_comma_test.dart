// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  assert(true);
  assert(true,);
  assert(true,"message");
  assert(true,"message",);
  assert(true,"message",extra);  //# 01: compile-time error
  assert(true,"message",,);  //# 02: compile-time error
}
