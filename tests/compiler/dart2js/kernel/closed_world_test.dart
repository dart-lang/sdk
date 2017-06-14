// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the closed world computed from [WorldImpact]s derived from kernel
// is equivalent to the original computed from resolution.
library dart2js.kernel.closed_world_test;

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/common/work.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/js_backend/backend.dart';
import 'package:compiler/src/js_backend/backend_usage.dart';
import 'package:compiler/src/js_backend/interceptor_data.dart';
import 'package:compiler/src/js_backend/resolution_listener.dart';
import 'package:compiler/src/js_backend/type_variable_handler.dart';
import 'package:compiler/src/ssa/kernel_impact.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/world.dart';
import 'impact_test.dart';
import '../memory_compiler.dart';
import '../serialization/helper.dart';
import '../serialization/model_test_helper.dart';
import '../equivalence/check_functions.dart';
import 'test_helpers.dart';

const SOURCE = const {
  'main.dart': '''
abstract class A {
  // redirecting factory in abstract class to other class
  factory A.a() = D.a;
  // redirecting factory in abstract class to factory in abstract class
  factory A.b() = B.a;
}
abstract class B implements A {
  factory B.a() => null;
}
class C implements B {
  // redirecting factory in concrete to other class
  factory C.a() = D.a;
}
class D implements C {
  D.a();
}
main(args) {
  new A.a();
  new A.b();
  new C.a();
  print(new List<String>()..add('Hello World!'));
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
    ElementResolutionWorldBuilder.useInstantiationMap = true;
    compiler.resolution.retainCachesForTesting = true;
    await compiler.run(entryPoint);
    compiler.resolutionWorldBuilder.closeWorld();

    JavaScriptBackend backend = compiler.backend;
    // Create a new resolution enqueuer and feed it with the [WorldImpact]s
    // computed from kernel through the [build] in `kernel_impact.dart`.
    List list = createResolutionEnqueuerListener(compiler);
    ResolutionEnqueuerListener resolutionEnqueuerListener = list[0];
    BackendUsageBuilder backendUsageBuilder = list[1];
    InterceptorDataBuilder interceptorDataBuilder = list[2];
    ResolutionEnqueuer enqueuer = new ResolutionEnqueuer(
        compiler.enqueuer,
        compiler.options,
        compiler.reporter,
        const TreeShakingEnqueuerStrategy(),
        resolutionEnqueuerListener,
        new ElementResolutionWorldBuilder(
            backend,
            compiler.resolution,
            backend.nativeBasicData,
            backend.nativeDataBuilder,
            interceptorDataBuilder,
            backendUsageBuilder,
            const OpenWorldStrategy()),
        new KernelTestWorkItemBuilder(compiler),
        'enqueuer from kernel');
    ClosedWorld closedWorld = computeClosedWorld(
        compiler.reporter, enqueuer, compiler.elementEnvironment);
    BackendUsage backendUsage = backendUsageBuilder.close();
    checkResolutionEnqueuers(
        backendUsage, backendUsage, compiler.enqueuer.resolution, enqueuer,
        typeEquivalence: (ResolutionDartType a, ResolutionDartType b) {
      return areTypesEquivalent(unalias(a), unalias(b));
    },
        elementFilter: elementFilter,
        verbose: arguments.verbose,
        // TODO(johnniwinther): Support class usage testing in presence of
        // redirecting constructors.
        skipClassUsageTesting: true);
    checkClosedWorlds(
        compiler.resolutionWorldBuilder.closedWorldForTesting, closedWorld,
        verbose: arguments.verbose);
  });
}

List createResolutionEnqueuerListener(Compiler compiler) {
  JavaScriptBackend backend = compiler.backend;
  BackendUsageBuilder backendUsageBuilder =
      new BackendUsageBuilderImpl(compiler.frontendStrategy.commonElements);
  InterceptorDataBuilder interceptorDataBuilder =
      new InterceptorDataBuilderImpl(
          backend.nativeBasicData,
          compiler.elementEnvironment,
          compiler.frontendStrategy.commonElements);
  ResolutionEnqueuerListener listener = new ResolutionEnqueuerListener(
      compiler.options,
      compiler.frontendStrategy.elementEnvironment,
      compiler.frontendStrategy.commonElements,
      backend.impacts,
      backend.nativeBasicData,
      interceptorDataBuilder,
      backendUsageBuilder,
      backend.rtiNeedBuilder,
      backend.mirrorsDataBuilder,
      backend.noSuchMethodRegistry,
      backend.customElementsResolutionAnalysis,
      backend.lookupMapResolutionAnalysis,
      backend.mirrorsResolutionAnalysis,
      new TypeVariableResolutionAnalysis(
          compiler.frontendStrategy.elementEnvironment,
          backend.impacts,
          backendUsageBuilder),
      backend.nativeResolutionEnqueuerForTesting,
      compiler.deferredLoadTask,
      backend.kernelTask);
  return [listener, backendUsageBuilder, interceptorDataBuilder];
}

ClosedWorld computeClosedWorld(DiagnosticReporter reporter,
    ResolutionEnqueuer enqueuer, ElementEnvironment elementEnvironment) {
  enqueuer.open(const ImpactStrategy(), elementEnvironment.mainFunction,
      elementEnvironment.libraries);
  enqueuer.forEach((WorkItem work) {
    enqueuer.applyImpact(work.run(), impactSource: work.element);
  });
  return enqueuer.worldBuilder.closeWorld();
}
