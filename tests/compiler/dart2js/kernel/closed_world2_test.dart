// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Partial test that the closed world computed from [WorldImpact]s derived from
// kernel is equivalent to the original computed from resolution.
library dart2js.kernel.closed_world2_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/tasks.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/js_backend/backend.dart'
    hide RuntimeTypesNeedBuilderImpl;
import 'package:compiler/src/js_backend/backend_impact.dart';
import 'package:compiler/src/js_backend/backend_usage.dart';
import 'package:compiler/src/js_backend/custom_elements_analysis.dart';
import 'package:compiler/src/js_backend/native_data.dart';
import 'package:compiler/src/js_backend/impact_transformer.dart';
import 'package:compiler/src/js_backend/interceptor_data.dart';
import 'package:compiler/src/js_backend/lookup_map_analysis.dart';
import 'package:compiler/src/js_backend/mirrors_analysis.dart'
    hide MirrorsResolutionAnalysisImpl;
import 'package:compiler/src/js_backend/mirrors_data.dart';
import 'package:compiler/src/js_backend/no_such_method_registry.dart';
import 'package:compiler/src/js_backend/resolution_listener.dart';
import 'package:compiler/src/js_backend/type_variable_handler.dart';
import 'package:compiler/src/native/enqueue.dart';
import 'package:compiler/src/native/resolver.dart';
import 'package:compiler/src/kernel/element_map.dart';
import 'package:compiler/src/kernel/kernel_strategy.dart';
import 'package:compiler/src/library_loader.dart';
import 'package:compiler/src/options.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'package:kernel/ast.dart' as ir;
import '../memory_compiler.dart';
import '../serialization/helper.dart';
import '../serialization/model_test_helper.dart';
import '../serialization/test_helper.dart';

import 'closed_world_test.dart' hide KernelWorkItemBuilder;
import 'impact_test.dart';

const SOURCE = const {
  'main.dart': '''
import 'dart:html';
import 'dart:typed_data';
import 'package:expect/expect.dart';

class ClassWithSetter {
  void set setter(_) {}
}

class Mixin {
  method1() {}
  method2() {}
  method3() {}
}
class Class1 = Object with Mixin;
class Class2 extends Object with Mixin {
  method3() {}
}
 
method1() {} // Deliberately the same name as the instance member in Mixin.

@NoInline()
main() {
  print('Hello World');
  ''.contains; // Trigger member closurization.
  new Element.div();
  new ClassWithSetter().setter = null;
  new Class1().method1();
  new Class2().method2();
  new Class2().method3();
  null is List<int>;
  method1(); // Both top level and instance method named 'method1' are live.
  #main; // Use a const symbol.
  new Int8List(0);
}
'''
};

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

enum ResultKind { crashes, errors, warnings, success, failure }

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
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

  enableDebugMode();

  print('---- analyze-only ------------------------------------------------');
  DiagnosticCollector collector = new DiagnosticCollector();
  Compiler compiler1 = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      diagnosticHandler: collector,
      options: [Flags.analyzeOnly, Flags.enableAssertMessage]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler1.resolution.retainCachesForTesting = true;
  await compiler1.run(entryPoint);
  if (collector.crashes.isNotEmpty) {
    print('Skipping due to crashes.');
    return ResultKind.crashes;
  }
  if (collector.errors.isNotEmpty && skipErrors) {
    print('Skipping due to errors.');
    return ResultKind.errors;
  }
  if (collector.warnings.isNotEmpty && skipWarnings) {
    print('Skipping due to warnings.');
    return ResultKind.warnings;
  }
  Expect.isFalse(compiler1.compilationFailed);
  ResolutionEnqueuer enqueuer1 = compiler1.enqueuer.resolution;
  BackendUsage backendUsage1 = compiler1.backend.backendUsage;
  ClosedWorld closedWorld1 = compiler1.resolutionWorldBuilder.closeWorld();

  print('---- analyze-all -------------------------------------------------');
  Compiler compiler = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [Flags.analyzeAll, Flags.useKernel, Flags.enableAssertMessage]);
  await compiler.run(entryPoint);
  compiler.resolutionWorldBuilder.closeWorld();
  ElementEnvironment environment1 = compiler.elementEnvironment;

  print('---- closed world from kernel ------------------------------------');
  Compiler compiler2 = compilerFor(
      entryPoint: entryPoint,
      memorySourceFiles: memorySourceFiles,
      options: [
        Flags.analyzeOnly,
        Flags.enableAssertMessage,
        Flags.loadFromDill
      ]);
  ElementResolutionWorldBuilder.useInstantiationMap = true;
  compiler2.resolution.retainCachesForTesting = true;
  KernelFrontEndStrategy frontEndStrategy = compiler2.frontEndStrategy;
  KernelToElementMap elementMap = frontEndStrategy.elementMap;
  compiler2.libraryLoader = new MemoryDillLibraryLoaderTask(
      elementMap,
      compiler2.reporter,
      compiler2.measurer,
      compiler.backend.kernelTask.program);
  await compiler2.run(entryPoint);
  Expect.isFalse(compiler2.compilationFailed);

  KernelEquivalence equivalence = new KernelEquivalence(elementMap);

  ElementEnvironment environment2 = compiler2.elementEnvironment;
  checkElementEnvironment(environment1, environment2, equivalence);

  ResolutionEnqueuer enqueuer2 = compiler2.enqueuer.resolution;
  BackendUsage backendUsage2 = compiler2.backend.backendUsage;
  ClosedWorld closedWorld2 = compiler2.resolutionWorldBuilder.closeWorld();
  checkBackendUsage(backendUsage1, backendUsage2, equivalence);

  checkResolutionEnqueuers(backendUsage1, backendUsage2, enqueuer1, enqueuer2,
      elementEquivalence: equivalence.entityEquivalence,
      typeEquivalence: (ResolutionDartType a, DartType b) {
    return equivalence.typeEquivalence(unalias(a), b);
  }, elementFilter: elementFilter, verbose: arguments.verbose);

  checkClosedWorlds(closedWorld1, closedWorld2, equivalence.entityEquivalence,
      verbose: arguments.verbose);

  return ResultKind.success;
}

void checkNativeBasicData(NativeBasicDataImpl data1, NativeBasicDataImpl data2,
    KernelEquivalence equivalence) {
  checkMapEquivalence(
      data1,
      data2,
      'nativeClassTagInfo',
      data1.nativeClassTagInfo,
      data2.nativeClassTagInfo,
      equivalence.entityEquivalence,
      (a, b) => a == b);
  // TODO(johnniwinther): Check the remaining properties.
}

void checkBackendUsage(BackendUsageImpl usage1, BackendUsageImpl usage2,
    KernelEquivalence equivalence) {
  checkSetEquivalence(
      usage1,
      usage2,
      'globalClassDependencies',
      usage1.globalClassDependencies,
      usage2.globalClassDependencies,
      equivalence.entityEquivalence);
  checkSetEquivalence(
      usage1,
      usage2,
      'globalFunctionDependencies',
      usage1.globalFunctionDependencies,
      usage2.globalFunctionDependencies,
      equivalence.entityEquivalence);
  checkSetEquivalence(
      usage1,
      usage2,
      'helperClassesUsed',
      usage1.helperClassesUsed,
      usage2.helperClassesUsed,
      equivalence.entityEquivalence);
  checkSetEquivalence(
      usage1,
      usage2,
      'helperFunctionsUsed',
      usage1.helperFunctionsUsed,
      usage2.helperFunctionsUsed,
      equivalence.entityEquivalence);
  check(
      usage1,
      usage2,
      'needToInitializeIsolateAffinityTag',
      usage1.needToInitializeIsolateAffinityTag,
      usage2.needToInitializeIsolateAffinityTag);
  check(
      usage1,
      usage2,
      'needToInitializeDispatchProperty',
      usage1.needToInitializeDispatchProperty,
      usage2.needToInitializeDispatchProperty);
  check(usage1, usage2, 'requiresPreamble', usage1.requiresPreamble,
      usage2.requiresPreamble);
  check(usage1, usage2, 'isInvokeOnUsed', usage1.isInvokeOnUsed,
      usage2.isInvokeOnUsed);
  check(usage1, usage2, 'isRuntimeTypeUsed', usage1.isRuntimeTypeUsed,
      usage2.isRuntimeTypeUsed);
  check(usage1, usage2, 'isIsolateInUse', usage1.isIsolateInUse,
      usage2.isIsolateInUse);
  check(usage1, usage2, 'isFunctionApplyUsed', usage1.isFunctionApplyUsed,
      usage2.isFunctionApplyUsed);
  check(usage1, usage2, 'isNoSuchMethodUsed', usage1.isNoSuchMethodUsed,
      usage2.isNoSuchMethodUsed);
}

checkElementEnvironment(ElementEnvironment env1, ElementEnvironment env2,
    KernelEquivalence equivalence) {
  checkSetEquivalence(env1, env2, 'libraries', env1.libraries, env2.libraries,
      equivalence.entityEquivalence,
      onSameElement: (LibraryEntity lib1, LibraryEntity lib2) {
    List<ClassEntity> classes2 = <ClassEntity>[];
    env1.forEachClass(lib1, (ClassEntity cls1) {
      String className = cls1.name;
      ClassEntity cls2 = env2.lookupClass(lib2, className);
      Expect.isNotNull(cls2, 'Missing class $className in $lib2');
      check(lib1, lib2, 'class:${className}', cls1, cls2,
          equivalence.entityEquivalence);

      check(cls1, cls2, 'superclass', env1.getSuperClass(cls1),
          env2.getSuperClass(cls2), equivalence.entityEquivalence);

      Map<MemberEntity, ClassEntity> members1 = <MemberEntity, ClassEntity>{};
      Map<MemberEntity, ClassEntity> members2 = <MemberEntity, ClassEntity>{};
      env1.forEachClassMember(cls1,
          (ClassEntity declarer1, MemberEntity member1) {
        members1[member1] = declarer1;
      });
      env1.forEachClassMember(cls1,
          (ClassEntity declarer2, MemberEntity member2) {
        members2[member2] = declarer2;
      });
      checkMapEquivalence(cls1, cls2, 'members', members1, members2,
          equivalence.entityEquivalence, equivalence.entityEquivalence);

      classes2.add(cls2);
    });
    env2.forEachClass(lib2, (ClassEntity cls2) {
      Expect.isTrue(classes2.contains(cls2), "Extra class $cls2 in $lib2");
    });
  });

  // TODO(johnniwinther): Test the remaining properties of [ElementEnvironment].
}

class MemoryDillLibraryLoaderTask extends DillLibraryLoaderTask {
  final ir.Program program;

  MemoryDillLibraryLoaderTask(KernelToElementMap elementMap,
      DiagnosticReporter reporter, Measurer measurer, this.program)
      : super(elementMap, null, null, reporter, measurer);

  Future<LoadedLibraries> loadLibrary(Uri resolvedUri,
      {bool skipFileWithPartOfTag: false}) async {
    return createLoadedLibraries(program);
  }
}
