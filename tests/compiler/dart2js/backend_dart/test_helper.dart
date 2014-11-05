// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_backend.test_helper;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart';
import '../../../../pkg/analyzer2dart/test/test_helper.dart';
import '../compiler_helper.dart';

/// Compiles the given dart code (which must include a 'main' function) and
/// returns the compiler.
Future<Compiler> compilerFor(String code) {
  MockCompiler compiler = new MockCompiler.internal(
      emitJavaScript: false,
      enableMinification: false);
  compiler.diagnosticHandler = createHandler(compiler, code);
  return compiler.init().then((_) {
    compiler.parseScript(code);

    Element element = compiler.mainApp.find('main');
    if (element == null) return null;

    compiler.mainFunction = element;
    compiler.phase = Compiler.PHASE_RESOLVING;
    compiler.backend.enqueueHelpers(compiler.enqueuer.resolution,
                                    compiler.globalDependencies);
    compiler.processQueue(compiler.enqueuer.resolution, element);
    compiler.world.populate();
    compiler.backend.onResolutionComplete();

    compiler.irBuilder.buildNodes(useNewBackend: true);

    return compiler;
  });
}

/// Test group using async_helper.
asyncTester(Group group, RunTest runTest) {
  asyncTest(() => Future.forEach(group.results, runTest));
}
