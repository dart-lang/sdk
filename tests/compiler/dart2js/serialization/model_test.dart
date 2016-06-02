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
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:compiler/src/universe/class_set.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';
import 'test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    SerializedData serializedData =
        await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await checkModels(entryPoint,
          sourceFiles: serializedData.toMemorySourceFiles(),
          resolutionInputs: serializedData.toUris());
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      arguments.forEachTest(serializedData, TESTS, checkModels);
    }
  });
}

Future checkModels(
    Uri entryPoint,
    {Map<String, String> sourceFiles: const <String, String>{},
     List<Uri> resolutionInputs,
     int index,
     Test test,
     bool verbose: false}) async {

  String testDescription = test != null ? test.name : '${entryPoint}';
  String id = index != null ? '$index: ' : '';
  print('------------------------------------------------------------------');
  print('compile normal ${id}${testDescription}');
  print('------------------------------------------------------------------');
  Compiler compilerNormal = compilerFor(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeOnly]);
  compilerNormal.resolution.retainCachesForTesting = true;
  await compilerNormal.run(entryPoint);
  compilerNormal.phase = Compiler.PHASE_DONE_RESOLVING;
  compilerNormal.world.populate();
  compilerNormal.backend.onResolutionComplete();

  print('------------------------------------------------------------------');
  print('compile deserialized ${id}${testDescription}');
  print('------------------------------------------------------------------');
  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: sourceFiles,
      resolutionInputs: resolutionInputs,
      options: [Flags.analyzeOnly]);
  compilerDeserialized.resolution.retainCachesForTesting = true;
  await compilerDeserialized.run(entryPoint);
  compilerDeserialized.phase = Compiler.PHASE_DONE_RESOLVING;
  compilerDeserialized.world.populate();
  compilerDeserialized.backend.onResolutionComplete();

  checkAllImpacts(
      compilerNormal, compilerDeserialized,
      verbose: verbose);

  checkSets(
      compilerNormal.resolverWorld.directlyInstantiatedClasses,
      compilerDeserialized.resolverWorld.directlyInstantiatedClasses,
      "Directly instantiated classes mismatch",
      areElementsEquivalent,
      verbose: verbose);

  checkSets(
      compilerNormal.resolverWorld.instantiatedTypes,
      compilerDeserialized.resolverWorld.instantiatedTypes,
      "Instantiated types mismatch",
      areTypesEquivalent,
      verbose: verbose);

  checkSets(
      compilerNormal.resolverWorld.isChecks,
      compilerDeserialized.resolverWorld.isChecks,
      "Is-check mismatch",
      areTypesEquivalent,
      verbose: verbose);

  checkSets(
      compilerNormal.enqueuer.resolution.processedElements,
      compilerDeserialized.enqueuer.resolution.processedElements,
      "Processed element mismatch",
      areElementsEquivalent,
      onSameElement: (a, b) {
        checkElements(
            compilerNormal, compilerDeserialized, a, b, verbose: verbose);
      },
      verbose: verbose);

  checkClassHierarchyNodes(
      compilerNormal,
      compilerDeserialized,
      compilerNormal.world.getClassHierarchyNode(
          compilerNormal.coreClasses.objectClass),
      compilerDeserialized.world.getClassHierarchyNode(
          compilerDeserialized.coreClasses.objectClass),
      verbose: verbose);
}

void checkElements(
    Compiler compiler1, Compiler compiler2,
    Element element1, Element element2,
    {bool verbose: false}) {
  if (element1.isFunction ||
      element1.isConstructor ||
      (element1.isField && element1.isInstanceMember)) {
    AstElement astElement1 = element1;
    AstElement astElement2 = element2;
    ClosureClassMap closureData1 =
    compiler1.closureToClassMapper.computeClosureToClassMapping(
        astElement1.resolvedAst);
    ClosureClassMap closureData2 =
    compiler2.closureToClassMapper.computeClosureToClassMapping(
        astElement2.resolvedAst);

    checkElementIdentities(closureData1, closureData2,
        '$element1.closureElement',
        closureData1.closureElement, closureData2.closureElement);
    checkElementIdentities(closureData1, closureData2,
        '$element1.closureClassElement',
        closureData1.closureClassElement, closureData2.closureClassElement);
    checkElementIdentities(closureData1, closureData2,
        '$element1.callElement',
        closureData1.callElement, closureData2.callElement);
    check(closureData1, closureData2,
        '$element1.thisLocal',
        closureData1.thisLocal, closureData2.thisLocal,
        areLocalsEquivalent);
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
  }
}

void checkMixinUses(
    Compiler compiler1, Compiler compiler2,
    ClassElement class1, ClassElement class2,
    {bool verbose: false}) {

  checkSets(
      compiler1.world.mixinUsesOf(class1),
      compiler2.world.mixinUsesOf(class2),
      "Mixin uses of $class1 vs $class2",
      areElementsEquivalent,
      verbose: verbose);

}

void checkClassHierarchyNodes(
    Compiler compiler1,
    Compiler compiler2,
    ClassHierarchyNode node1, ClassHierarchyNode node2,
    {bool verbose: false}) {
  if (verbose) {
    print('Checking $node1 vs $node2');
  }
  Expect.isTrue(
      areElementsEquivalent(node1.cls, node2.cls),
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
        checkClassHierarchyNodes(compiler1, compiler2,
            child, other, verbose: verbose);
        found = true;
        break;
      }
    }
    if (!found) {
      if (child.isInstantiated) {
        print('Missing subclass ${child.cls} of ${node1.cls} '
            'in ${node2.directSubclasses}');
        print(compiler1.world.dump(
            verbose ? compiler1.coreClasses.objectClass : node1.cls));
        print(compiler2.world.dump(
            verbose ? compiler2.coreClasses.objectClass : node2.cls));
      }
      Expect.isFalse(child.isInstantiated,
          'Missing subclass ${child.cls} of ${node1.cls} in '
              '${node2.directSubclasses}');
    }
  }
  checkMixinUses(compiler1, compiler2, node1.cls, node2.cls, verbose: verbose);
}

void checkSets(
    Iterable set1,
    Iterable set2,
    String messagePrefix,
    bool sameElement(a, b),
    {bool failOnUnfound: true,
     bool verbose: false,
     void onSameElement(a, b)}) {
  List common = [];
  List unfound = [];
  Set remaining = computeSetDifference(
      set1, set2, common, unfound,
      sameElement: sameElement,
      checkElements: onSameElement);
  StringBuffer sb = new StringBuffer();
  sb.write("$messagePrefix:");
  if (verbose) {
    sb.write("\n Common:\n  ${common.join('\n  ')}");
  }
  if (unfound.isNotEmpty || verbose) {
    sb.write("\n Unfound:\n  ${unfound.join('\n  ')}");
  }
  if (remaining.isNotEmpty || verbose) {
    sb.write("\n Extra: \n  ${remaining.join('\n  ')}");
  }
  String message = sb.toString();
  if (unfound.isNotEmpty || remaining.isNotEmpty) {

    if (failOnUnfound || remaining.isNotEmpty) {
      Expect.fail(message);
    } else {
      print(message);
    }
  } else if (verbose) {
    print(message);
  }
}

String defaultToString(obj) => '$obj';

void checkMaps(
    Map map1,
    Map map2,
    String messagePrefix,
    bool sameKey(a, b),
    bool sameValue(a, b),
    {bool failOnUnfound: true,
     bool failOnMismatch: true,
     bool verbose: false,
     String keyToString(key): defaultToString,
     String valueToString(key): defaultToString}) {
  List common = [];
  List unfound = [];
  List<List> mismatch = <List>[];
  Set remaining = computeSetDifference(
      map1.keys, map2.keys, common, unfound,
      sameElement: sameKey,
      checkElements: (k1, k2) {
        var v1 = map1[k1];
        var v2 = map2[k2];
        if (!sameValue(v1, v2)) {
          mismatch.add([k1, k2]);
        }
      });
  StringBuffer sb = new StringBuffer();
  sb.write("$messagePrefix:");
  if (verbose) {
    sb.write("\n Common: \n");
    for (List pair in common) {
      var k1 = pair[0];
      var k2 = pair[1];
      var v1 = map1[k1];
      var v2 = map2[k2];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  if (unfound.isNotEmpty || verbose) {
    sb.write("\n Unfound: \n");
    for (var k1 in unfound) {
      var v1 = map1[k1];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
    }
  }
  if (remaining.isNotEmpty || verbose) {
    sb.write("\n Extra: \n");
    for (var k2 in remaining) {
      var v2 = map2[k2];
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  if (mismatch.isNotEmpty || verbose) {
    sb.write("\n Mismatch: \n");
    for (List pair in mismatch) {
      var k1 = pair[0];
      var k2 = pair[1];
      var v1 = map1[k1];
      var v2 = map2[k2];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  String message = sb.toString();
  if (unfound.isNotEmpty || mismatch.isNotEmpty || remaining.isNotEmpty) {
    if ((unfound.isNotEmpty && failOnUnfound) ||
        (mismatch.isNotEmpty && failOnMismatch) ||
        remaining.isNotEmpty) {
      Expect.fail(message);
    } else {
      print(message);
    }
  } else if (verbose) {
    print(message);
  }
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
  checkMaps(a.capturedVariables, b.capturedVariables,
      'ClosureScope.capturedVariables',
      areLocalsEquivalent,
      areElementsEquivalent);
  checkSets(a.boxedLoopVariables, b.boxedLoopVariables,
      'ClosureScope.boxedLoopVariables',
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