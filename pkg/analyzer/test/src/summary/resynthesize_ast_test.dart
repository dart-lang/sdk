// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.resynthesize_ast_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/resynthesize.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart'
    show PackageBundleAssembler;
import 'package:analyzer/task/dart.dart' show PARSED_UNIT;
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'resynthesize_test.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(ResynthesizeAstTest);
}

@reflectiveTest
class ResynthesizeAstTest extends ResynthesizeTest {
  final Set<Source> serializedSources = new Set<Source>();
  final PackageBundleAssembler bundleAssembler = new PackageBundleAssembler();
  final Map<Uri, UnlinkedUnitBuilder> uriToUnit = <Uri, UnlinkedUnitBuilder>{};

  @override
  bool get checkPropagatedTypes => false;

  @override
  void checkLibrary(String text,
      {bool allowErrors: false, bool dumpSummaries: false}) {
    Source source = addTestSource(text);
    SummaryResynthesizer resynthesizer = _encodeLibrary(source);
    LibraryElementImpl resynthesized =
        resynthesizer.getLibraryElement(source.uri.toString());
    LibraryElementImpl original = context.computeLibraryElement(source);
    checkLibraryElements(original, resynthesized);
  }

  @override
  TestSummaryResynthesizer encodeDecodeLibrarySource(Source source) {
    return _encodeLibrary(source);
  }

  @override
  void test_const_invokeConstructor_named() {
    // TODO(scheglov) fix me
  }

  @override
  void test_constructor_withCycles_const() {
    // TODO(scheglov) fix me
  }

  @override
  void test_inferred_function_type_in_generic_class_constructor() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_named() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_named_prefixed() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_unnamed() {
    // TODO(scheglov) fix me
  }

  @override
  void test_metadata_constructor_call_with_args() {
    // TODO(scheglov) fix me
  }

  @override
  void test_type_reference_to_import_part_in_subdir() {
    // TODO(scheglov) fix me
  }

  @override
  void test_unused_type_parameter() {
    // TODO(paulberry): fix.
  }

  TestSummaryResynthesizer _encodeLibrary(Source source) {
    addLibrary('dart:core');
    _serializeLibrary(source);

    PackageBundle bundle =
        new PackageBundle.fromBuffer(bundleAssembler.assemble().toBuffer());

    Map<String, UnlinkedUnit> unlinkedSummaries = <String, UnlinkedUnit>{};
    Map<String, LinkedLibrary> linkedSummaries = <String, LinkedLibrary>{};
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      String uri = bundle.unlinkedUnitUris[i];
      unlinkedSummaries[uri] = bundle.unlinkedUnits[i];
    }
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      String uri = bundle.linkedLibraryUris[i];
      linkedSummaries[uri] = bundle.linkedLibraries[i];
    }

    return new TestSummaryResynthesizer(
        null, context, unlinkedSummaries, linkedSummaries);
  }

  UnlinkedUnitBuilder _getUnlinkedUnit(Source source) {
    return uriToUnit.putIfAbsent(source.uri, () {
      CompilationUnit unit = context.computeResult(source, PARSED_UNIT);
      UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
      bundleAssembler.addUnlinkedUnit(source, unlinkedUnit);
      return unlinkedUnit;
    });
  }

  void _serializeLibrary(Source librarySource) {
    if (!serializedSources.add(librarySource)) {
      return;
    }

    Source resolveRelativeUri(String relativeUri) {
      Source resolvedSource =
          context.sourceFactory.resolveUri(librarySource, relativeUri);
      if (resolvedSource == null) {
        throw new StateError('Could not resolve $relativeUri in the context of '
            '$librarySource (${librarySource.runtimeType})');
      }
      return resolvedSource;
    }

    UnlinkedUnitBuilder getPart(String relativeUri) {
      return _getUnlinkedUnit(resolveRelativeUri(relativeUri));
    }

    UnlinkedPublicNamespace getImport(String relativeUri) {
      return getPart(relativeUri).publicNamespace;
    }

    UnlinkedUnitBuilder definingUnit = _getUnlinkedUnit(librarySource);
    LinkedLibraryBuilder linkedLibrary =
        prelink(definingUnit, getPart, getImport);
    bundleAssembler.addLinkedLibrary(
        librarySource.uri.toString(), linkedLibrary);
    linkedLibrary.dependencies.skip(1).forEach((LinkedDependency d) {
      _serializeLibrary(resolveRelativeUri(d.uri));
    });
  }
}
