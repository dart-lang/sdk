// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the closed world computed from [WorldImpact]s derived from kernel
// is equivalent to the original computed from resolution.
library dart2js.kernel.closed_world_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/js_backend/backend.dart';
import 'package:compiler/src/js_backend/type_variable_handler.dart';
import 'package:compiler/src/resolution/registry.dart';
import 'package:compiler/src/resolution/tree_elements.dart';
import 'package:compiler/src/ssa/kernel_impact.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:compiler/src/universe/feature.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'impact_test.dart';
import '../memory_compiler.dart';
import '../serialization/helper.dart';
import '../serialization/model_test_helper.dart';

const SOURCE = const {
  'main.dart': '''
main() {
  print('Hello World!');
}
'''
};

main(List<String> args) {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  asyncTest(() async {
    enableDebugMode();
    Compiler compiler = compilerFor(
        entryPoint: entryPoint,
        memorySourceFiles: memorySourceFiles,
        options: [
          Flags.analyzeOnly,
          Flags.useKernel,
          Flags.enableAssertMessage
        ]);
    compiler.resolution.retainCachesForTesting = true;
    await compiler.run(entryPoint);
    compiler.openWorld.closeWorld(compiler.reporter);

    JavaScriptBackend backend = compiler.backend;
    // Create a new resolution enqueuer and feed it with the [WorldImpact]s
    // computed from kernel through the [build] in `kernel_impact.dart`.
    ResolutionEnqueuer enqueuer = new ResolutionEnqueuer(
        compiler.enqueuer,
        compiler.options,
        compiler.resolution,
        compiler.enqueuerFilter,
        const TreeShakingEnqueuerStrategy(),
        compiler.globalDependencies,
        backend,
        compiler.commonElements,
        compiler.cacheStrategy);
    // TODO(johnniwinther): Store backend info separately. This replacement is
    // made to reset a field in [TypeVariableHandler] that prevents it from
    // enqueuing twice.
    backend.typeVariableHandler = new TypeVariableHandler(compiler);

    backend.enqueueHelpers(enqueuer);
    enqueuer.addToWorkList(compiler.mainFunction);
    enqueuer.forEach((work) {
      AstElement element = work.element;
      ResolutionImpact resolutionImpact = build(compiler, element.resolvedAst);
      WorldImpact worldImpact = compiler.backend.impactTransformer
          .transformResolutionImpact(enqueuer, resolutionImpact);
      enqueuer.registerProcessedElement(element);
      enqueuer.applyImpact(compiler.impactStrategy, worldImpact,
          impactSource: element);
    });
    ClosedWorld closedWorld =
        enqueuer.universe.openWorld.closeWorld(compiler.reporter);

    checkResolutionEnqueuers(compiler.enqueuer.resolution, enqueuer,
        typeEquivalence: (DartType a, DartType b) {
      return areTypesEquivalent(unalias(a), unalias(b));
    }, elementFilter: (Element element) {
      if (element is ConstructorElement && element.isRedirectingFactory) {
        // Redirecting factory constructors are skipped in kernel.
        return false;
      }
      return true;
    }, verbose: arguments.verbose);
    checkClosedWorlds(compiler.closedWorld, closedWorld,
        verbose: arguments.verbose);
  });
}
