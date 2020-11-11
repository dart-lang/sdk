// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:expect/expect.dart';

main() {
  // The error cannot be null.
  Expect.throwsTypeError(() {
    Future.error(null);
  });
}
