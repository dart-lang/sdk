// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:typed_data';

@NoInline()
use(s) => s;

main() {
  // In dart2js ByteData should have an interceptor so that it doesn't end up
  // as an unknown JS object.
  // This test is just to make sure that dart2js doesn't crash.
  use(new ByteData(1).toString());
}
