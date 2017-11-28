// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'inference_test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(
        dataDir, computeMemberAstTypeMasks, computeMemberIrTypeMasks,
        args: args, options: [stopAfterTypeInference]);
  });
}
