// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:async_helper/async_helper.dart';
import '../equivalence/id_equivalence_helper.dart';
import 'inference_test_helper.dart';

const List<String> skipForKernel = const <String>[
  // TODO(johnniwinther): Remove this when issue 31767 is fixed.
  'mixin_constructor_default_parameter_values.dart',
];

main(List<String> args) {
  asyncTest(() async {
    Directory dataDir = new Directory.fromUri(Platform.script.resolve('data'));
    await checkTests(
        dataDir, computeMemberAstTypeMasks, computeMemberIrTypeMasks,
        libDirectory: new Directory.fromUri(Platform.script.resolve('libs')),
        forUserLibrariesOnly: true,
        args: args,
        options: [stopAfterTypeInference],
        skipForKernel: skipForKernel);
  });
}
