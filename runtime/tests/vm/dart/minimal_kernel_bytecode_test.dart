// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=minimal_kernel_script.dart

// Tests that dill file produced with --minimal-kernel --gen-bytecode
// options works as expected.

import 'minimal_kernel_test.dart' as test;

main() async {
  await test.compileAndRunMinimalDillTest(['--gen-bytecode']);
}
