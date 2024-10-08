// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-multi-module-stress-test-mode --extra-compiler-option=--no-js-compatibility

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/util/memory_compiler.dart' as dart2js;
import 'package:expect/expect.dart';

import 'data_loader_helper.dart';

main() async {
  asyncStart();
  final main = 'main.dart';
  final entryPoint = Uri.parse('memory:$main');
  final platformDillBytes =
      await loadFileWrapper('../../../dart2js_platform.dill');
  final result = await dart2js.runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: {
        main: 'main() {}',
        'package.yaml': '{ "configVersion": 1, "packages": []}',
        'binaries': '',
        'dart2js_platform.dill': platformDillBytes
      },
      packageConfig: Uri.parse('memory:package.yaml'),
      platformBinaries: Uri.parse('memory:binaries'));
  Expect.isTrue(result.isSuccess);
  asyncEnd();
}
