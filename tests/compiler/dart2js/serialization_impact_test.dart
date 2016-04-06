// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_impact_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'memory_compiler.dart';
import 'serialization_helper.dart';
import 'serialization_test.dart';

main(List<String> arguments) {
  asyncTest(() async {
    String serializedData = await serializeDartCore();
    if (arguments.isNotEmpty) {
      Uri entryPoint = Uri.base.resolve(nativeToUriPath(arguments.last));
      await check(serializedData, entryPoint);
    } else {
      Uri entryPoint = Uri.parse('memory:main.dart');
      await check(serializedData, entryPoint, {'main.dart': 'main() {}'});
    }
  });
}

Future check(
  String serializedData,
  Uri entryPoint,
  [Map<String, String> sourceFiles = const <String, String>{}]) async {

  Compiler compilerNormal = compilerFor(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeOnly]);
  compilerNormal.resolution.retainCachesForTesting = true;
  await compilerNormal.run(entryPoint);

  Compiler compilerDeserialized = compilerFor(
      memorySourceFiles: sourceFiles,
      options: [Flags.analyzeOnly]);
  compilerDeserialized.resolution.retainCachesForTesting = true;
  deserialize(compilerDeserialized, serializedData);
  await compilerDeserialized.run(entryPoint);

  checkResolutionImpacts(compilerNormal, compilerDeserialized, verbose: true);
}

/// Check equivalence of [impact1] and [impact2].
void checkImpacts(Element element1, Element element2,
                  ResolutionImpact impact1, ResolutionImpact impact2,
                  {bool verbose: false}) {
  if (impact1 == null || impact2 == null) return;

  if (verbose) {
    print('Checking impacts for $element1 vs $element2');
  }

  testResolutionImpactEquivalence(impact1, impact2, const CheckStrategy());
}


/// Check equivalence between all resolution impacts common to [compiler1] and
/// [compiler2].
void checkResolutionImpacts(
    Compiler compiler1,
    Compiler compiler2,
    {bool verbose: false}) {

  void checkMembers(Element member1, Element member2) {
    if (member1.isClass && member2.isClass) {
      ClassElement class1 = member1;
      ClassElement class2 = member2;
      class1.forEachLocalMember((m1) {
        checkMembers(m1, class2.lookupLocalMember(m1.name));
      });
      return;
    }

    if (!compiler1.resolution.hasResolutionImpact(member1)) {
      return;
    }

    if (member2 == null) {
      return;
    }

    if (areElementsEquivalent(member1, member2)) {
      checkImpacts(
          member1, member2,
          compiler1.resolution.getResolutionImpact(member1),
          compiler2.serialization.deserializer.getResolutionImpact(member2),
          verbose: verbose);
    }
  }

  for (LibraryElement library1 in compiler1.libraryLoader.libraries) {
    LibraryElement library2 =
        compiler2.libraryLoader.lookupLibrary(library1.canonicalUri);
    if (library2 != null) {
      library1.forEachLocalMember((Element member1) {
        checkMembers(member1, library2.localLookup(member1.name));
      });

    }
  }
}