// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_model_test;

import 'dart:async';
import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/util/enumset.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';
import 'test_helper.dart';

/// Number of tests that are not part of the automatic test grouping.
int SKIP_COUNT = 2;

/// Number of groups that the [TESTS] are split into.
int SPLIT_COUNT = 5;

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.uri != null) {
      Uri entryPoint = arguments.uri;
      SerializationResult result =
          await measure('${entryPoint}', 'serialize', () {
        return serialize(entryPoint,
            memorySourceFiles: serializedData.toMemorySourceFiles(),
            resolutionInputs: serializedData.toUris(),
            dataUri: Uri.parse('memory:test.data'));
      });
      await checkModels(entryPoint,
          sourceFiles: serializedData
              .toMemorySourceFiles(result.serializedData.toMemorySourceFiles()),
          resolutionInputs:
              serializedData.toUris(result.serializedData.toUris()));
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      await arguments.forEachTest(serializedData, TESTS, checkModels);
    }
    printMeasurementResults();
  });
}

Future checkModels(Uri entryPoint,
    {Map<String, String> sourceFiles: const <String, String>{},
    List<Uri> resolutionInputs,
    int index,
    Test test,
    bool verbose: false}) async {
  String testDescription = test != null ? test.name : '${entryPoint}';
  String id = index != null ? '$index: ' : '';
  String title = '${id}${testDescription}';
  Compiler compilerNormal = await measure(title, 'compile normal', () async {
    Compiler compilerNormal = compilerFor(
        memorySourceFiles: sourceFiles, options: [Flags.analyzeOnly]);
    compilerNormal.resolution.retainCachesForTesting = true;
    await compilerNormal.run(entryPoint);
    compilerNormal.closeResolution();
    return compilerNormal;
  });

  Compiler compilerDeserialized =
      await measure(title, 'compile deserialized', () async {
    Compiler compilerDeserialized = compilerFor(
        memorySourceFiles: sourceFiles,
        resolutionInputs: resolutionInputs,
        options: [Flags.analyzeOnly]);
    compilerDeserialized.resolution.retainCachesForTesting = true;
    await compilerDeserialized.run(entryPoint);
    compilerDeserialized.closeResolution();
    return compilerDeserialized;
  });

  return measure(title, 'check models', () async {
    checkAllImpacts(compilerNormal, compilerDeserialized, verbose: verbose);
    checkResolutionEnqueuers(compilerNormal.enqueuer.resolution,
        compilerDeserialized.enqueuer.resolution,
        verbose: verbose);
    checkClosedWorlds(
        compilerNormal.closedWorld, compilerDeserialized.closedWorld,
        verbose: verbose);
    checkBackendInfo(compilerNormal, compilerDeserialized, verbose: verbose);
  });
}

void checkResolutionEnqueuers(
    ResolutionEnqueuer enqueuer1, ResolutionEnqueuer enqueuer2,
    {bool typeEquivalence(DartType a, DartType b): areTypesEquivalent,
    bool elementFilter(Element element),
    bool verbose: false}) {
  checkSets(enqueuer1.processedEntities, enqueuer2.processedEntities,
      "Processed element mismatch", areElementsEquivalent,
      elementFilter: elementFilter, verbose: verbose);

  ResolutionWorldBuilderImpl worldBuilder1 = enqueuer1.universe;
  ResolutionWorldBuilderImpl worldBuilder2 = enqueuer2.universe;

  checkMaps(
      worldBuilder1.getInstantiationMap(),
      worldBuilder2.getInstantiationMap(),
      "Instantiated classes mismatch",
      areElementsEquivalent,
      (a, b) => areInstantiationInfosEquivalent(a, b, typeEquivalence),
      verbose: verbose);

  checkSets(
      enqueuer1.universe.directlyInstantiatedClasses,
      enqueuer2.universe.directlyInstantiatedClasses,
      "Directly instantiated classes mismatch",
      areElementsEquivalent,
      verbose: verbose);

  checkSets(
      enqueuer1.universe.instantiatedTypes,
      enqueuer2.universe.instantiatedTypes,
      "Instantiated types mismatch",
      typeEquivalence,
      verbose: verbose);

  checkSets(enqueuer1.universe.isChecks, enqueuer2.universe.isChecks,
      "Is-check mismatch", typeEquivalence,
      verbose: verbose);

  JavaScriptBackend backend1 = enqueuer1.backend;
  JavaScriptBackend backend2 = enqueuer2.backend;
  Expect.equals(backend1.hasInvokeOnSupport, backend2.hasInvokeOnSupport,
      "JavaScriptBackend.hasInvokeOnSupport mismatch");
  Expect.equals(
      backend1.hasFunctionApplySupport,
      backend2.hasFunctionApplySupport,
      "JavaScriptBackend.hasFunctionApplySupport mismatch");
  Expect.equals(backend1.hasRuntimeTypeSupport, backend2.hasRuntimeTypeSupport,
      "JavaScriptBackend.hasRuntimeTypeSupport mismatch");
  Expect.equals(backend1.hasIsolateSupport, backend2.hasIsolateSupport,
      "JavaScriptBackend.hasIsolateSupport mismatch");
}

void checkClosedWorlds(ClosedWorld closedWorld1, ClosedWorld closedWorld2,
    {bool verbose: false}) {
  checkClassHierarchyNodes(
      closedWorld1,
      closedWorld2,
      closedWorld1.getClassHierarchyNode(closedWorld1.coreClasses.objectClass),
      closedWorld2.getClassHierarchyNode(closedWorld2.coreClasses.objectClass),
      verbose: verbose);
}

void checkBackendInfo(Compiler compilerNormal, Compiler compilerDeserialized,
    {bool verbose: false}) {
  checkSets(
      compilerNormal.enqueuer.resolution.processedEntities,
      compilerDeserialized.enqueuer.resolution.processedEntities,
      "Processed element mismatch",
      areElementsEquivalent, onSameElement: (a, b) {
    checkElements(compilerNormal, compilerDeserialized, a, b, verbose: verbose);
  }, verbose: verbose);
  Expect.equals(
      compilerNormal.deferredLoadTask.isProgramSplit,
      compilerDeserialized.deferredLoadTask.isProgramSplit,
      "isProgramSplit mismatch");

  Map<ConstantValue, OutputUnit> constants1 =
      compilerNormal.deferredLoadTask.outputUnitForConstantsForTesting;
  Map<ConstantValue, OutputUnit> constants2 =
      compilerDeserialized.deferredLoadTask.outputUnitForConstantsForTesting;
  checkSets(
      constants1.keys,
      constants2.keys,
      'deferredLoadTask._outputUnitForConstants.keys',
      areConstantValuesEquivalent,
      failOnUnfound: false,
      failOnExtra: false,
      onSameElement: (ConstantValue value1, ConstantValue value2) {
    OutputUnit outputUnit1 = constants1[value1];
    OutputUnit outputUnit2 = constants2[value2];
    checkOutputUnits(
        outputUnit1,
        outputUnit2,
        'for ${value1.toStructuredText()} '
        'vs ${value2.toStructuredText()}');
  }, onUnfoundElement: (ConstantValue value1) {
    OutputUnit outputUnit1 = constants1[value1];
    Expect.isTrue(outputUnit1.isMainOutput,
        "Missing deferred constant: ${value1.toStructuredText()}");
  }, onExtraElement: (ConstantValue value2) {
    OutputUnit outputUnit2 = constants2[value2];
    Expect.isTrue(outputUnit2.isMainOutput,
        "Extra deferred constant: ${value2.toStructuredText()}");
  }, elementToString: (a) {
    return '${a.toStructuredText()} -> ${constants1[a]}/${constants2[a]}';
  });
}

void checkElements(
    Compiler compiler1, Compiler compiler2, Element element1, Element element2,
    {bool verbose: false}) {
  if (element1.isAbstract) return;
  if (element1.isFunction ||
      element1.isConstructor ||
      (element1.isField && element1.isInstanceMember)) {
    AstElement astElement1 = element1;
    AstElement astElement2 = element2;
    ClosureClassMap closureData1 = compiler1.closureToClassMapper
        .getClosureToClassMapping(astElement1.resolvedAst);
    ClosureClassMap closureData2 = compiler2.closureToClassMapper
        .getClosureToClassMapping(astElement2.resolvedAst);

    checkElementIdentities(
        closureData1,
        closureData2,
        '$element1.closureElement',
        closureData1.closureElement,
        closureData2.closureElement);
    checkElementIdentities(
        closureData1,
        closureData2,
        '$element1.closureClassElement',
        closureData1.closureClassElement,
        closureData2.closureClassElement);
    checkElementIdentities(closureData1, closureData2, '$element1.callElement',
        closureData1.callElement, closureData2.callElement);
    check(closureData1, closureData2, '$element1.thisLocal',
        closureData1.thisLocal, closureData2.thisLocal, areLocalsEquivalent);
    checkMaps(
        closureData1.freeVariableMap,
        closureData2.freeVariableMap,
        "$element1.freeVariableMap",
        areLocalsEquivalent,
        areCapturedVariablesEquivalent,
        verbose: verbose);
    checkMaps(
        closureData1.capturingScopes,
        closureData2.capturingScopes,
        "$element1.capturingScopes",
        areNodesEquivalent,
        areClosureScopesEquivalent,
        verbose: verbose,
        keyToString: nodeToString);
    checkSets(
        closureData1.variablesUsedInTryOrGenerator,
        closureData2.variablesUsedInTryOrGenerator,
        "$element1.variablesUsedInTryOrGenerator",
        areLocalsEquivalent,
        verbose: verbose);
    if (element1 is MemberElement && element2 is MemberElement) {
      MemberElement member1 = element1.implementation;
      MemberElement member2 = element2.implementation;
      checkSets(member1.nestedClosures, member2.nestedClosures,
          "$member1.nestedClosures", areElementsEquivalent, verbose: verbose,
          onSameElement: (a, b) {
        LocalFunctionElement localFunction1 = a.expression;
        LocalFunctionElement localFunction2 = b.expression;
        checkElementIdentities(localFunction1, localFunction2, 'enclosingClass',
            localFunction1.enclosingClass, localFunction2.enclosingClass);
        testResolvedAstEquivalence(localFunction1.resolvedAst,
            localFunction2.resolvedAst, const CheckStrategy());
      });
    }
  }
  JavaScriptBackend backend1 = compiler1.backend;
  JavaScriptBackend backend2 = compiler2.backend;
  Expect.equals(
      backend1.inlineCache.getCurrentCacheDecisionForTesting(element1),
      backend2.inlineCache.getCurrentCacheDecisionForTesting(element2),
      "Inline cache decision mismatch for $element1 vs $element2");

  checkElementOutputUnits(compiler1, compiler2, element1, element2);
}

void checkMixinUses(ClosedWorld closedWorld1, ClosedWorld closedWorld2,
    ClassElement class1, ClassElement class2,
    {bool verbose: false}) {
  checkSets(closedWorld1.mixinUsesOf(class1), closedWorld2.mixinUsesOf(class2),
      "Mixin uses of $class1 vs $class2", areElementsEquivalent,
      verbose: verbose);
}

void checkClassHierarchyNodes(
    ClosedWorld closedWorld1,
    ClosedWorld closedWorld2,
    ClassHierarchyNode node1,
    ClassHierarchyNode node2,
    {bool verbose: false}) {
  if (verbose) {
    print('Checking $node1 vs $node2');
  }
  Expect.isTrue(areElementsEquivalent(node1.cls, node2.cls),
      "Element identity mismatch for ${node1.cls} vs ${node2.cls}.");
  Expect.equals(
      node1.isDirectlyInstantiated,
      node2.isDirectlyInstantiated,
      "Value mismatch for 'isDirectlyInstantiated' "
      "for ${node1.cls} vs ${node2.cls}.");
  Expect.equals(
      node1.isIndirectlyInstantiated,
      node2.isIndirectlyInstantiated,
      "Value mismatch for 'isIndirectlyInstantiated' "
      "for ${node1.cls} vs ${node2.cls}.");
  // TODO(johnniwinther): Enforce a canonical and stable order on direct
  // subclasses.
  for (ClassHierarchyNode child in node1.directSubclasses) {
    bool found = false;
    for (ClassHierarchyNode other in node2.directSubclasses) {
      if (areElementsEquivalent(child.cls, other.cls)) {
        checkClassHierarchyNodes(closedWorld1, closedWorld2, child, other,
            verbose: verbose);
        found = true;
        break;
      }
    }
    if (!found) {
      if (child.isInstantiated) {
        print('Missing subclass ${child.cls} of ${node1.cls} '
            'in ${node2.directSubclasses}');
        print(closedWorld1
            .dump(verbose ? closedWorld1.coreClasses.objectClass : node1.cls));
        print(closedWorld2
            .dump(verbose ? closedWorld2.coreClasses.objectClass : node2.cls));
      }
      Expect.isFalse(
          child.isInstantiated,
          'Missing subclass ${child.cls} of ${node1.cls} in '
          '${node2.directSubclasses}');
    }
  }
  checkMixinUses(closedWorld1, closedWorld2, node1.cls, node2.cls,
      verbose: verbose);
}

bool areLocalsEquivalent(Local a, Local b) {
  if (a == b) return true;
  if (a == null || b == null) return false;

  if (a is Element) {
    return b is Element && areElementsEquivalent(a as Element, b as Element);
  } else {
    return a.runtimeType == b.runtimeType &&
        areElementsEquivalent(a.executableContext, b.executableContext);
  }
}

bool areCapturedVariablesEquivalent(CapturedVariable a, CapturedVariable b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a is ClosureFieldElement && b is ClosureFieldElement) {
    return areElementsEquivalent(a.closureClass, b.closureClass) &&
        areLocalsEquivalent(a.local, b.local);
  } else if (a is BoxFieldElement && b is BoxFieldElement) {
    return areElementsEquivalent(a.variableElement, b.variableElement) &&
        areLocalsEquivalent(a.box, b.box);
  }
  return false;
}

bool areClosureScopesEquivalent(ClosureScope a, ClosureScope b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (!areLocalsEquivalent(a.boxElement, b.boxElement)) {
    return false;
  }
  checkMaps(
      a.capturedVariables,
      b.capturedVariables,
      'ClosureScope.capturedVariables',
      areLocalsEquivalent,
      areElementsEquivalent);
  checkSets(a.boxedLoopVariables, b.boxedLoopVariables,
      'ClosureScope.boxedLoopVariables', areElementsEquivalent);
  return true;
}

String nodeToString(Node node) {
  String text = '$node';
  if (text.length > 40) {
    return '(${node.runtimeType}) ${text.substring(0, 37)}...';
  }
  return '(${node.runtimeType}) $text';
}

void checkElementOutputUnits(Compiler compiler1, Compiler compiler2,
    Element element1, Element element2) {
  OutputUnit outputUnit1 =
      compiler1.deferredLoadTask.getOutputUnitForElementForTesting(element1);
  OutputUnit outputUnit2 =
      compiler2.deferredLoadTask.getOutputUnitForElementForTesting(element2);
  checkOutputUnits(outputUnit1, outputUnit2, 'for $element1 vs $element2');
}

void checkOutputUnits(
    OutputUnit outputUnit1, OutputUnit outputUnit2, String message) {
  if (outputUnit1 == null && outputUnit2 == null) return;
  check(outputUnit1, outputUnit2, 'OutputUnit.isMainOutput $message',
      outputUnit1.isMainOutput, outputUnit2.isMainOutput);
  checkSetEquivalence(
      outputUnit1,
      outputUnit2,
      'OutputUnit.imports $message',
      outputUnit1.imports,
      outputUnit2.imports,
      (a, b) => areElementsEquivalent(a.declaration, b.declaration));
}

bool areInstantiationInfosEquivalent(InstantiationInfo info1,
    InstantiationInfo info2, bool typeEquivalence(DartType a, DartType b)) {
  checkMaps(
      info1.instantiationMap,
      info2.instantiationMap,
      'instantiationMap of\n   '
      '${info1.instantiationMap}\nvs ${info2.instantiationMap}',
      areElementsEquivalent,
      (a, b) => areSetsEquivalent(
          a, b, (a, b) => areInstancesEquivalent(a, b, typeEquivalence)));
  return true;
}

bool areInstancesEquivalent(Instance instance1, Instance instance2,
    bool typeEquivalence(DartType a, DartType b)) {
  return typeEquivalence(instance1.type, instance2.type) &&
      instance1.kind == instance2.kind &&
      instance1.isRedirection == instance2.isRedirection;
}
