// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool assertsChecked() {
  bool checked = false;
  try {
    assert(false);
  } on AssertionError catch (error) {
    checked = true;
  }
  return checked;
}

main() async {
  bool fault = false;
  try {
    assert(await false);
  } on AssertionError catch (error) {
    fault = true;
  }
  Expect.equals(assertsChecked(), fault);
}
