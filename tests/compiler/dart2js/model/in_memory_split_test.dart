// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/js_backend/inferred_data.dart';
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

String code = '''
main() {}
''';
main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': code},
        beforeRun: (Compiler compiler) {
          compiler.stopAfterTypeInference = true;
        });
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    GlobalTypeInferenceResults globalInferenceResults =
        cloneInferenceResults(compiler.globalInference.resultsForTesting);
    compiler.generateJavaScriptCode(globalInferenceResults);
  });
}

GlobalTypeInferenceResults cloneInferenceResults(
    GlobalTypeInferenceResultsImpl result) {
  JClosedWorld closedWorld = result.closedWorld;
  InferredData inferredData = result.inferredData;
  return new GlobalTypeInferenceResultsImpl(
      closedWorld,
      inferredData,
      result.memberResults,
      result.parameterResults,
      result.checkedForGrowableLists,
      result.returnsListElementTypeSet);
}
