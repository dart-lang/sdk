// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_elements_test;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/public_namespace_computer.dart'
    as public_namespace;
import 'package:analyzer/src/summary/summarize_elements.dart'
    as summarize_elements;
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import '../abstract_single_unit.dart';
import '../context/abstract_context.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(SummarizeElementsTest);
}

/**
 * Override of [SummaryTest] which creates summaries from the element model.
 */
@reflectiveTest
class SummarizeElementsTest extends AbstractSingleUnitTest with SummaryTest {
  /**
   * The list of absolute unit URIs corresponding to the compilation units in
   * [unlinkedUnits].
   */
  List<String> unitUris;

  /**
   * Map containing all source files in this test, and their corresponding file
   * contents.
   */
  final Map<Source, String> _fileContents = <Source, String>{};

  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  @override
  bool get checkAstDerivedData => false;

  @override
  bool get expectAbsoluteUrisInDependencies => true;

  /**
   * Determine the analysis options that should be used for this test.
   */
  AnalysisOptionsImpl get options =>
      new AnalysisOptionsImpl()..enableGenericMethods = true;

  @override
  bool get skipFullyLinkedData => false;

  @override
  bool get skipNonConstInitializers => true;

  @override
  bool get strongMode => false;

  @override
  Source addNamedSource(String filePath, String contents) {
    Source source = super.addSource(filePath, contents);
    _fileContents[source] = contents;
    return source;
  }

  @override
  DartSdk createDartSdk() => AbstractContextTest.SHARED_MOCK_SDK;

  /**
   * Serialize the library containing the given class [element], then
   * deserialize it and return the summary of the class.
   */
  UnlinkedClass serializeClassElement(ClassElement element) {
    serializeLibraryElement(element.library);
    return findClass(element.name, failIfAbsent: true);
  }

  /**
   * Serialize the given [library] element, then deserialize it and store the
   * resulting summary in [linked] and [unlinkedUnits].
   */
  void serializeLibraryElement(LibraryElement library) {
    summarize_elements.LibrarySerializationResult serializedLib =
        summarize_elements.serializeLibrary(
            library, context.typeProvider, context.analysisOptions.strongMode);
    {
      List<int> buffer = serializedLib.linked.toBuffer();
      linked = new LinkedLibrary.fromBuffer(buffer);
      validateLinkedLibrary(linked);
    }
    unlinkedUnits = serializedLib.unlinkedUnits.map((UnlinkedUnitBuilder b) {
      List<int> buffer = b.toBuffer();
      return new UnlinkedUnit.fromBuffer(buffer);
    }).toList();
    unitUris = serializedLib.unitUris;
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Source source = addTestSource(text);
    _fileContents[source] = text;
    LibraryElement library = context.computeLibraryElement(source);
    if (!allowErrors) {
      assertNoErrorsInSource(source);
    }
    serializeLibraryElement(library);
    expect(unlinkedUnits[0].imports.length, linked.importDependencies.length);
    expect(unlinkedUnits[0].exports.length, linked.exportDependencies.length);
    expect(linked.units.length, unlinkedUnits.length);
    for (int i = 0; i < linked.units.length; i++) {
      expect(unlinkedUnits[i].references.length,
          lessThanOrEqualTo(linked.units[i].references.length));
    }
    verifyPublicNamespace();
  }

  @override
  void setUp() {
    super.setUp();
    prepareAnalysisContext(options);
  }

  test_class_no_superclass() {
    UnlinkedClass cls =
        serializeClassElement(context.typeProvider.objectType.element);
    expect(cls.supertype, isNull);
    expect(cls.hasNoSupertype, isTrue);
  }

  /**
   * Verify that [public_namespace.computePublicNamespace] produces data that's
   * equivalent to that produced by [summarize_elements.serializeLibrary].
   */
  void verifyPublicNamespace() {
    for (int i = 0; i < unlinkedUnits.length; i++) {
      Source source = context.sourceFactory.forUri(unitUris[i]);
      String text = _fileContents[source];
      if (text == null) {
        if (!allowMissingFiles) {
          fail('Could not find file while verifying public namespace: '
              '${unitUris[i]}');
        }
      } else {
        UnlinkedPublicNamespace namespace =
            computePublicNamespaceFromText(text, source);
        expect(canonicalize(namespace),
            canonicalize(unlinkedUnits[i].publicNamespace),
            reason: 'publicNamespace(${unitUris[i]})');
      }
    }
  }
}
