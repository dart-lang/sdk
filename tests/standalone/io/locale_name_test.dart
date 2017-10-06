// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

main() {
  try {
    Platform.localeName;
  } catch (e, s) {
    Expect.fail("Platform.localeName threw: $e\n$s\n");
  }
  Expect.isNotNull(Platform.localeName);
  Expect.isTrue(Platform.localeName is String);
  print(Platform.localeName);
}
