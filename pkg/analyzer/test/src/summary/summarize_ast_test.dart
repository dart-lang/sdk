// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_ast_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'summary_common.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LinkedSummarizeAstSpecTest);
  });
}

@reflectiveTest
class LinkedSummarizeAstSpecTest extends LinkedSummarizeAstTest {
  @override
  bool get strongMode => false;

  @override
  @failingTest
  test_bottom_reference_shared() {
    super.test_bottom_reference_shared();
  }

  @override
  @failingTest
  test_closure_executable_with_bottom_return_type() {
    super.test_closure_executable_with_bottom_return_type();
  }

  @override
  @failingTest
  test_closure_executable_with_imported_return_type() {
    super.test_closure_executable_with_imported_return_type();
  }

  @override
  @failingTest
  test_closure_executable_with_return_type_from_closure() {
    super.test_closure_executable_with_return_type_from_closure();
  }

  @override
  @failingTest
  test_closure_executable_with_unimported_return_type() {
    super.test_closure_executable_with_unimported_return_type();
  }

  @override
  @failingTest
  test_implicit_dependencies_follow_other_dependencies() {
    super.test_implicit_dependencies_follow_other_dependencies();
  }

  @override
  @failingTest
  test_initializer_executable_with_bottom_return_type() {
    super.test_initializer_executable_with_bottom_return_type();
  }

  @override
  @failingTest
  test_initializer_executable_with_imported_return_type() {
    super.test_initializer_executable_with_imported_return_type();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure() {
    super.test_initializer_executable_with_return_type_from_closure();
  }

  @override
  @failingTest
  test_initializer_executable_with_return_type_from_closure_field() {
    super.test_initializer_executable_with_return_type_from_closure_field();
  }

  @override
  @failingTest
  test_initializer_executable_with_unimported_return_type() {
    super.test_initializer_executable_with_unimported_return_type();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() {
    super.test_syntheticFunctionType_inGenericClass();
  }
}

/**
 * Override of [SummaryTest] which creates linked summaries directly from the
 * AST.
 */
@reflectiveTest
abstract class LinkedSummarizeAstTest extends SummaryLinkerTest
    with SummaryTest {
  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  LinkerInputs linkerInputs;

  @override
  bool get skipFullyLinkedData => false;

  @override
  bool get skipNonConstInitializers => false;

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Map<String, UnlinkedUnitBuilder> uriToUnit = this._filesToLink.uriToUnit;
    linkerInputs = createLinkerInputs(text);
    linked = link(
        linkerInputs.linkedLibraries,
        linkerInputs.getDependency,
        linkerInputs.getUnit,
        (name) => null,
        strongMode)[linkerInputs.testDartUri.toString()];
    expect(linked, isNotNull);
    validateLinkedLibrary(linked);
    unlinkedUnits = <UnlinkedUnit>[linkerInputs.unlinkedDefiningUnit];
    for (String relativeUriStr
        in linkerInputs.unlinkedDefiningUnit.publicNamespace.parts) {
      Uri relativeUri;
      try {
        relativeUri = Uri.parse(relativeUriStr);
      } on FormatException {
        unlinkedUnits.add(new UnlinkedUnitBuilder());
        continue;
      }

      UnlinkedUnit unit = uriToUnit[
          resolveRelativeUri(linkerInputs.testDartUri, relativeUri).toString()];
      if (unit == null) {
        if (!allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUriStr');
        }
      } else {
        unlinkedUnits.add(unit);
      }
    }
  }

  test_class_no_superclass() {
    UnlinkedClass cls = serializeClassText('part of dart.core; class Object {}',
        className: 'Object');
    expect(cls.supertype, isNull);
    expect(cls.hasNoSupertype, isTrue);
  }
}

/**
 * Instances of the class [LinkerInputs] encapsulate the necessary information
 * to pass to the summary linker.
 */
class LinkerInputs {
  final bool _allowMissingFiles;
  final Map<String, UnlinkedUnit> _uriToUnit;
  final Uri testDartUri;
  final UnlinkedUnit unlinkedDefiningUnit;
  final Map<String, LinkedLibrary> _dependentLinkedLibraries;
  final Map<String, UnlinkedUnit> _dependentUnlinkedUnits;

  LinkerInputs(
      this._allowMissingFiles,
      this._uriToUnit,
      this.testDartUri,
      this.unlinkedDefiningUnit,
      this._dependentLinkedLibraries,
      this._dependentUnlinkedUnits);

  Set<String> get linkedLibraries => _uriToUnit.keys.toSet();

  String getDeclaredVariable(String name) {
    return null;
  }

  LinkedLibrary getDependency(String absoluteUri) {
    Map<String, LinkedLibrary> sdkLibraries =
        SerializedMockSdk.instance.uriToLinkedLibrary;
    LinkedLibrary linkedLibrary =
        sdkLibraries[absoluteUri] ?? _dependentLinkedLibraries[absoluteUri];
    if (linkedLibrary == null && !_allowMissingFiles) {
      Set<String> librariesAvailable = sdkLibraries.keys.toSet();
      librariesAvailable.addAll(_dependentLinkedLibraries.keys);
      fail('Linker unexpectedly requested LinkedLibrary for "$absoluteUri".'
          '  Libraries available: ${librariesAvailable.toList()}');
    }
    return linkedLibrary;
  }

  UnlinkedUnit getUnit(String absoluteUri) {
    if (absoluteUri == null) {
      return null;
    }
    UnlinkedUnit unit = _uriToUnit[absoluteUri] ??
        SerializedMockSdk.instance.uriToUnlinkedUnit[absoluteUri] ??
        _dependentUnlinkedUnits[absoluteUri];
    if (unit == null && !_allowMissingFiles) {
      fail('Linker unexpectedly requested unit for "$absoluteUri".');
    }
    return unit;
  }
}

/**
 * Base class providing the ability to run the summary linker using summaries
 * build from ASTs.
 */
abstract class SummaryLinkerTest {
  /**
   * Information about the files to be linked.
   */
  _FilesToLink _filesToLink = new _FilesToLink();

  /**
   * A test will set this to `true` if it contains `import`, `export`, or
   * `part` declarations that deliberately refer to non-existent files.
   */
  bool get allowMissingFiles;

  /**
   * Add the given package bundle as a dependency so that it may be referenced
   * by the files under test.
   */
  void addBundle(String path, PackageBundle bundle) {
    _filesToLink.summaryDataStore.addBundle(path, bundle);
  }

  /**
   * Add the given source file so that it may be referenced by the file under
   * test.
   */
  Source addNamedSource(String filePath, String contents) {
    CompilationUnit unit = _parseText(contents);
    UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
    _filesToLink.uriToUnit[absUri(filePath)] = unlinkedUnit;
    // Tests using SummaryLinkerTest don't actually need the returned
    // Source, so we can safely return `null`.
    return null;
  }

  LinkerInputs createLinkerInputs(String text,
      {String path: '/test.dart', String uri}) {
    uri ??= absUri(path);
    Uri testDartUri = Uri.parse(uri);
    UnlinkedUnitBuilder unlinkedDefiningUnit =
        createUnlinkedSummary(testDartUri, text);
    _filesToLink.uriToUnit[testDartUri.toString()] = unlinkedDefiningUnit;
    LinkerInputs linkerInputs = new LinkerInputs(
        allowMissingFiles,
        _filesToLink.uriToUnit,
        testDartUri,
        unlinkedDefiningUnit,
        _filesToLink.summaryDataStore.linkedMap,
        _filesToLink.summaryDataStore.unlinkedMap);
    // Reset _filesToLink in case the test needs to start a new package bundle.
    _filesToLink = new _FilesToLink();
    return linkerInputs;
  }

  /**
   * Link together the given file, along with any other files passed to
   * [addNamedSource], to form a package bundle.  Reset the state of the buffers
   * accumulated by [addNamedSource] and [addBundle] so that further bundles
   * can be created.
   */
  PackageBundleBuilder createPackageBundle(String text,
      {String path: '/test.dart', String uri}) {
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    LinkerInputs linkerInputs = createLinkerInputs(text, path: path, uri: uri);
    Map<String, LinkedLibraryBuilder> linkedLibraries = link(
        linkerInputs.linkedLibraries,
        linkerInputs.getDependency,
        linkerInputs.getUnit,
        linkerInputs.getDeclaredVariable,
        true);
    linkedLibraries.forEach(assembler.addLinkedLibrary);
    linkerInputs._uriToUnit.forEach((String uri, UnlinkedUnit unit) {
      // Note: it doesn't matter what we store for the hash because it isn't
      // used in these tests.
      assembler.addUnlinkedUnitWithHash(uri, unit, 'HASH');
    });
    return assembler.assemble();
  }

  UnlinkedUnitBuilder createUnlinkedSummary(Uri uri, String text) =>
      serializeAstUnlinked(_parseText(text));

  CompilationUnit _parseText(String text) {
    CharSequenceReader reader = new CharSequenceReader(text);
    Scanner scanner =
        new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    parser.enableAssertInitializer = true;
    CompilationUnit unit = parser.parseCompilationUnit(token);
    unit.lineInfo = new LineInfo(scanner.lineStarts);
    return unit;
  }
}

/**
 * [_FilesToLink] stores information about a set of files to be linked together.
 * This information is grouped into a class to allow it to be reset easily when
 * [SummaryLinkerTest.createLinkerInputs] is called.
 */
class _FilesToLink {
  /**
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit
   * passed to [addNamedSource].
   */
  Map<String, UnlinkedUnitBuilder> uriToUnit = <String, UnlinkedUnitBuilder>{};

  /**
   * Information about summaries to be included in the link process.
   */
  SummaryDataStore summaryDataStore = new SummaryDataStore([]);
}
