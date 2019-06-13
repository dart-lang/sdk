// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:modular_test/src/find_sdk_root.dart';

main() {
  asyncTest(() async {
    Expect.equals(Platform.script.resolve("../../../../"), await findRoot());
  });
}
