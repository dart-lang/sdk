// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool inCheckedMode() {
  try {
    int i = 'hest';
  } catch (e) {
    return true;
  }
  return false;
}

main() {
  if (inCheckedMode()) {
    Expect.throws(() {
      List<int> t = new List<String>();
    });
  }
}
