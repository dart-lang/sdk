// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=../../../../tests/language/mixin/regress_flutter_55345_test.dart

// Runs regress_flutter_55345_test.dart using AOT kernel generation split into
// 2 steps using '--from-dill' option.

import 'dart:io' show Platform;

import 'split_aot_kernel_generation_test.dart'
    show runSplitAOTKernelGenerationTest;

main() async {
  await runSplitAOTKernelGenerationTest(Platform.script.resolve(
      '../../../../tests/language/mixin/regress_flutter_55345_test.dart'));
}
