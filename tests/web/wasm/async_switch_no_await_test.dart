// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() async {
  var flag = false;
  switch (2) {
    L:
    case 1:
      flag = true;
      break;
    case 2:
      continue L;
  }
  Expect.isTrue(flag);
}
