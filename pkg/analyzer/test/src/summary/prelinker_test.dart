// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.prelinker_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summarize_elements_test.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(PrelinkerTest);
}

/**
 * Override of [SummaryTest] which verifies the correctness of the prelinker by
 * creating summaries from the element model, discarding their prelinked
 * information, and then recreating it using the prelinker.
 */
@reflectiveTest
class PrelinkerTest extends SummarizeElementsTest {
  final Map<String, UnlinkedPublicNamespace> uriToPublicNamespace =
      <String, UnlinkedPublicNamespace>{};

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  bool get skipFullyLinkedData => true;

  @override
  bool get strongMode => false;

  @override
  Source addNamedSource(String filePath, String contents) {
    Source source = super.addNamedSource(filePath, contents);
    uriToPublicNamespace[absUri(filePath)] =
        computePublicNamespaceFromText(contents, source);
    return source;
  }

  String resolveToAbsoluteUri(LibraryElement library, String relativeUri) {
    Source resolvedSource =
        context.sourceFactory.resolveUri(library.source, relativeUri);
    if (resolvedSource == null) {
      fail('Failed to resolve relative uri "$relativeUri"');
    }
    return resolvedSource.uri.toString();
  }

  @override
  void serializeLibraryElement(LibraryElement library) {
    super.serializeLibraryElement(library);
    uriToPublicNamespace[library.source.uri.toString()] =
        unlinkedUnits[0].publicNamespace;
    Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};
    expect(unlinkedUnits.length, unitUris.length);
    for (int i = 1; i < unlinkedUnits.length; i++) {
      uriToUnit[unitUris[i]] = unlinkedUnits[i];
    }
    UnlinkedUnit getPart(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(library, relativeUri);
      UnlinkedUnit unit = uriToUnit[absoluteUri];
      if (unit == null) {
        fail('Prelinker unexpectedly requested unit for "$relativeUri"'
            ' (resolves to "$absoluteUri").');
      }
      return unit;
    }
    UnlinkedPublicNamespace getImport(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(library, relativeUri);
      UnlinkedPublicNamespace namespace = SerializedMockSdk
          .instance.uriToUnlinkedUnit[absoluteUri]?.publicNamespace;
      if (namespace == null) {
        namespace = uriToPublicNamespace[absoluteUri];
      }
      if (namespace == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested namespace for "$relativeUri"'
            ' (resolves to "$absoluteUri").'
            '  Namespaces available: ${uriToPublicNamespace.keys}');
      }
      return namespace;
    }
    linked = new LinkedLibrary.fromBuffer(
        prelink(unlinkedUnits[0], getPart, getImport).toBuffer());
    validateLinkedLibrary(linked);
  }
}
