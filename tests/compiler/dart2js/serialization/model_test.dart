// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_model_test;

import 'dart:async';
import 'dart:io';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/backend_api.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/element_serialization.dart';
import 'package:compiler/src/serialization/impact_serialization.dart';
import 'package:compiler/src/serialization/json_serializer.dart';
import 'package:compiler/src/serialization/serialization.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/serialization/task.dart';
import 'package:compiler/src/universe/world_impact.dart';
import 'package:compiler/src/universe/class_set.dart';
import 'package:compiler/src/universe/use.dart';
import '../memory_compiler.dart';
import 'helper.dart';
import 'test_data.dart';
import 'test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    Arguments arguments = new Arguments.from(args);
    String serializedData = await serializeDartCore(arguments: arguments);
    if (arguments.filename != null) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.filename));
      await check(serializedData, entryPoint);
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      for (Test test in TESTS) {
        print('==============================================================');
        print(test.sourceFiles);
        await check(
          serializedData,
          entryPoint,
          sourceFiles: test.sourceFiles,
          verbose: arguments.verbose);
      }
    }
  });
}

Future check(
  String serializedData,
  Uri entryPoint,
  {Map<String, String> sourceFiles: const <String, String>{},
   bool verbose: false}) async {

  print('------------------------------------------------------------------');
  print('compile normal');
  print('------------------------------------------------------------------');
  Compiler compilerNormal = compilerFor(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeOnly]);
  compilerNormal.resolution.retainCachesForTesting = true;
  await compilerNormal.run(entryPoint);
  compilerNormal.phase = Compiler.PHASE_DONE_RESOLVING;
  compilerNormal.world.populate();

  print('------------------------------------------------------------------');
  print('compile deserialized');
  print('------------------------------------------------------------------');
  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeOnly]);
  compilerDeserialized.resolution.retainCachesForTesting = true;
  deserialize(compilerDeserialized, serializedData);
  await compilerDeserialized.run(entryPoint);
  compilerDeserialized.phase = Compiler.PHASE_DONE_RESOLVING;
  compilerDeserialized.world.populate();

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
      Expect.isFalse(child.isInstantiated,
          'Missing subclass ${child.cls} of ${node1.cls}');
    }
  }
  checkMixinUses(compiler1, compiler2, node1.cls, node2.cls, verbose: verbose);
}

void checkSets(
    Iterable set1,
    Iterable set2,
    String messagePrefix,
    bool areEquivalent(a, b),
    {bool failOnUnfound: true,
     bool verbose: false}) {
  List common = [];
  List unfound = [];
  Set remaining = computeSetDifference(
      set1, set2, common, unfound, areEquivalent);
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
