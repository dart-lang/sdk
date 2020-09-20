// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void main() {
  method(<int>[]);
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_FUNCTION
// [cfe] Method not found: 'method'.
}
