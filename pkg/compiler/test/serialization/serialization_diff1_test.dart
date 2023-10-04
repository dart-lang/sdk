// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';

import 'serialization_diff_helper.dart';

void main(List<String> args) {
  asyncTest(() async {
    await runTests(args, 1);
  });
}
