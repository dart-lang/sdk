// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_model_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/closure.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/deferred_load.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/world.dart';
import '../memory_compiler.dart';
import '../equivalence/check_helpers.dart';
import '../equivalence/check_functions.dart';
import 'helper.dart';
import 'test_data.dart';

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
    ElementEnvironment elementEnvironment =
        compilerNormal.frontendStrategy.elementEnvironment;
    compilerNormal.closeResolution(elementEnvironment.mainFunction);
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
    ElementEnvironment elementEnvironment =
        compilerDeserialized.frontendStrategy.elementEnvironment;
    compilerDeserialized.closeResolution(elementEnvironment.mainFunction);
    return compilerDeserialized;
  });

  return measure(title, 'check models', () async {
    checkAllImpacts(compilerNormal, compilerDeserialized, verbose: verbose);
    ClosedWorld closedWorld1 =
        compilerNormal.resolutionWorldBuilder.closedWorldForTesting;
    ClosedWorld closedWorld2 =
        compilerNormal.resolutionWorldBuilder.closedWorldForTesting;
    checkResolutionEnqueuers(
        closedWorld1.backendUsage,
        closedWorld2.backendUsage,
        compilerNormal.enqueuer.resolution,
        compilerDeserialized.enqueuer.resolution,
        verbose: verbose);
    checkClosedWorlds(closedWorld1, closedWorld2,
        // Serialized native data include non-live members.
        allowExtra: true,
        verbose: verbose);
    checkBackendInfo(compilerNormal, compilerDeserialized, verbose: verbose);
  });
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

  Iterable<ConstantValue> constants1 =
      compilerNormal.deferredLoadTask.constantsForTesting;
  Iterable<ConstantValue> constants2 =
      compilerDeserialized.deferredLoadTask.constantsForTesting;
  checkSets(
      constants1,
      constants2,
      'deferredLoadTask._outputUnitForConstants.keys',
      areConstantValuesEquivalent,
      failOnUnfound: false,
      failOnExtra: false,
      onSameElement: (ConstantValue value1, ConstantValue value2) {
    checkOutputUnits(
        compilerNormal,
        compilerDeserialized,
        compilerNormal.deferredLoadTask.outputUnitForConstant(value1),
        compilerDeserialized.deferredLoadTask.outputUnitForConstant(value2),
        'for ${value1.toStructuredText()} '
        'vs ${value2.toStructuredText()}');
  }, onUnfoundElement: (ConstantValue value1) {
    OutputUnit outputUnit1 =
        compilerNormal.deferredLoadTask.outputUnitForConstant(value1);
    Expect.isTrue(outputUnit1.isMainOutput,
        "Missing deferred constant: ${value1.toStructuredText()}");
  }, onExtraElement: (ConstantValue value2) {
    OutputUnit outputUnit2 =
        compilerDeserialized.deferredLoadTask.outputUnitForConstant(value2);
    Expect.isTrue(outputUnit2.isMainOutput,
        "Extra deferred constant: ${value2.toStructuredText()}");
  }, elementToString: (a) {
    OutputUnit o1 = compilerNormal.deferredLoadTask.outputUnitForConstant(a);
    OutputUnit o2 =
        compilerDeserialized.deferredLoadTask.outputUnitForConstant(a);
    return '${a.toStructuredText()} -> ${o1}/${o2}';
  });
}

void checkElements(
    Compiler compiler1, Compiler compiler2, Element element1, Element element2,
    {bool verbose: false}) {
  if (element1.isAbstract) return;
  if (element1.isFunction ||
      element1.isConstructor ||
      (element1.isField && element1.isInstanceMember)) {
    ClosureRepresentationInfo closureData1 = compiler1
        .backendStrategy.closureDataLookup
        .getClosureInfoForMember(element1 as MemberElement);
    ClosureRepresentationInfo closureData2 = compiler2
        .backendStrategy.closureDataLookup
        .getClosureInfoForMember(element2 as MemberElement);

    checkElementIdentities(
        closureData1,
        closureData2,
        '$element1.closureEntity',
        closureData1.closureEntity,
        closureData2.closureEntity);
    checkElementIdentities(
        closureData1,
        closureData2,
        '$element1.closureClassEntity',
        closureData1.closureClassEntity,
        closureData2.closureClassEntity);
    checkElementIdentities(closureData1, closureData2, '$element1.callMethod',
        closureData1.callMethod, closureData2.callMethod);
    check(closureData1, closureData2, '$element1.thisLocal',
        closureData1.thisLocal, closureData2.thisLocal, areLocalsEquivalent);

    checkElementListIdentities(
        closureData1,
        closureData2,
        "$element1.createdFieldEntities",
        closureData1.createdFieldEntities,
        closureData2.createdFieldEntities);
    check(
        closureData1,
        closureData2,
        '$element1.thisFieldEntity',
        closureData1.thisFieldEntity,
        closureData2.thisFieldEntity,
        areLocalsEquivalent);
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
  if (element1 is MethodElement && element2 is MethodElement) {
    Expect.equals(
        backend1.inlineCache.getCurrentCacheDecisionForTesting(element1),
        backend2.inlineCache.getCurrentCacheDecisionForTesting(element2),
        "Inline cache decision mismatch for $element1 vs $element2");
  }

  checkElementOutputUnits(compiler1, compiler2, element1, element2);
}

bool areLocalsEquivalent(LocalVariable a, LocalVariable b) {
  if (a == b) return true;
  if (a == null || b == null) return false;

  if (a is Element) {
    return b is Element && areElementsEquivalent(a as Element, b as Element);
  } else {
    return a.runtimeType == b.runtimeType &&
        areElementsEquivalent(a.executableContext, b.executableContext);
  }
}

bool areCapturedVariablesEquivalent(FieldEntity a, FieldEntity b) {
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

bool areCapturedScopesEquivalent(CapturedScope a, CapturedScope b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (!areLocalsEquivalent(a.context, b.context)) {
    return false;
  }
  if (!areLocalsEquivalent(a.thisLocal, b.thisLocal)) {
    return false;
  }
  var aBoxed = {};
  a.forEachBoxedVariable((k, v) => aBoxed[k] = v);
  var bBoxed = {};
  b.forEachBoxedVariable((k, v) => bBoxed[k] = v);
  checkMaps(aBoxed, bBoxed, 'CapturedScope.boxedVariables', areLocalsEquivalent,
      areElementsEquivalent);
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
  checkOutputUnits(compiler1, compiler2, outputUnit1, outputUnit2,
      'for $element1 vs $element2');
}

void checkOutputUnits(Compiler compiler1, Compiler compiler2,
    OutputUnit outputUnit1, OutputUnit outputUnit2, String message) {
  if (outputUnit1 == null && outputUnit2 == null) return;
  check(outputUnit1, outputUnit2, 'OutputUnit.isMainOutput $message',
      outputUnit1.isMainOutput, outputUnit2.isMainOutput);
  checkSetEquivalence(
      outputUnit1,
      outputUnit2,
      'OutputUnit.imports $message',
      compiler1.deferredLoadTask.getImportNames(outputUnit1),
      compiler2.deferredLoadTask.getImportNames(outputUnit2),
      (a, b) => areElementsEquivalent(a.declaration, b.declaration));
}
