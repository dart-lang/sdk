// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int badReturnTypeAsync() async {} // //# 01: compile-time error
int badReturnTypeAsyncStar() async* {} // //# 02: compile-time error
int badReturnTypeSyncStar() sync* {} // //# 03: compile-time error

void main() {}
