// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.reserialization_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/invariant.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:expect/expect.dart';
import '../equivalence/check_functions.dart';
import 'helper.dart';
import 'equivalence_test.dart';

main(List<String> args) {
  // Ensure that we can print out constant expressions.
  DEBUG_MODE = true;

  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  if (arguments.filename != null) {
    entryPoint = Uri.parse(arguments.filename);
  } else {
    entryPoint = Uri.parse('dart:core');
  }
  asyncTest(() async {
    await testReserialization(entryPoint);
  });
}

Future testReserialization(Uri entryPoint) async {
  SerializationResult result1 = await serialize(entryPoint);
  Compiler compiler1 = result1.compiler;
  SerializedData serializedData1 = result1.serializedData;
  Iterable<LibraryElement> libraries1 = compiler1.libraryLoader.libraries;

  SerializationResult result2 = await serialize(entryPoint,
      memorySourceFiles: serializedData1.toMemorySourceFiles(),
      resolutionInputs: serializedData1.toUris(),
      deserializeCompilationDataForTesting: true);
  Compiler compiler2 = result2.compiler;
  SerializedData serializedData2 = result2.serializedData;
  Iterable<LibraryElement> libraries2 = compiler2.libraryLoader.libraries;

  SerializationResult result3 = await serialize(entryPoint,
      memorySourceFiles: serializedData2.toMemorySourceFiles(),
      resolutionInputs: serializedData2.toUris(),
      deserializeCompilationDataForTesting: true);
  Compiler compiler3 = result3.compiler;
  Iterable<LibraryElement> libraries3 = compiler3.libraryLoader.libraries;

  for (LibraryElement library1 in libraries1) {
    LibraryElement library2 = libraries2.firstWhere((LibraryElement library2) {
      return library2.canonicalUri == library1.canonicalUri;
    });
    Expect.isNotNull(
        library2, "No library found for ${library1.canonicalUri}.");
    checkLibraryContent('library1', 'library2', 'library', library1, library2);

    LibraryElement library3 = libraries3.firstWhere((LibraryElement library3) {
      return library3.canonicalUri == library1.canonicalUri;
    });
    Expect.isNotNull(
        library3, "No library found for ${library1.canonicalUri}.");
    checkLibraryContent('library1', 'library3', 'library', library1, library3);
  }

  checkAllResolvedAsts(compiler1, compiler2);
  checkAllResolvedAsts(compiler1, compiler3);

  checkAllImpacts(compiler1, compiler2);
  checkAllImpacts(compiler1, compiler3);
}
