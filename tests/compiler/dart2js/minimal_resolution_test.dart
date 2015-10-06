// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that elements are not needlessly required by dart2js.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

main() {
  asyncTest(() async {
    await analyze('main() {}');
    await analyze('main() => proxy;', proxyConstant: true);
  });
}

analyze(String code,
        {bool proxyConstant: false}) async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code},
      options: ['--analyze-only']);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  Expect.equals(proxyConstant, compiler.proxyConstant != null);
}
