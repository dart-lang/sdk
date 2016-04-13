// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.summary.summarize_ast_test;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/link.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LinkedSummarizeAstSpecTest);
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
  test_field_propagated_type_final_immediate() {
    super.test_field_propagated_type_final_immediate();
  }

  @override
  @failingTest
  test_fully_linked_references_follow_other_references() {
    super.test_fully_linked_references_follow_other_references();
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
  test_initializer_executable_with_return_type_from_closure_local() {
    super.test_initializer_executable_with_return_type_from_closure_local();
  }

  @override
  @failingTest
  test_initializer_executable_with_unimported_return_type() {
    super.test_initializer_executable_with_unimported_return_type();
  }

  @override
  @failingTest
  test_linked_reference_reuse() {
    super.test_linked_reference_reuse();
  }

  @override
  @failingTest
  test_linked_type_dependency_reuse() {
    super.test_linked_type_dependency_reuse();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericClass() {
    super.test_syntheticFunctionType_inGenericClass();
  }

  @override
  @failingTest
  test_syntheticFunctionType_inGenericFunction() {
    super.test_syntheticFunctionType_inGenericFunction();
  }

  @override
  @failingTest
  test_syntheticFunctionType_noArguments() {
    super.test_syntheticFunctionType_noArguments();
  }

  @override
  @failingTest
  test_syntheticFunctionType_withArguments() {
    super.test_syntheticFunctionType_withArguments();
  }

  @override
  @failingTest
  test_unused_type_parameter() {
    super.test_unused_type_parameter();
  }

  @override
  @failingTest
  test_variable_propagated_type_final_immediate() {
    super.test_variable_propagated_type_final_immediate();
  }

  @override
  @failingTest
  test_variable_propagated_type_new_reference() {
    super.test_variable_propagated_type_new_reference();
  }

  @override
  @failingTest
  test_variable_propagated_type_omit_dynamic() {
    super.test_variable_propagated_type_omit_dynamic();
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

  @override
  bool get checkAstDerivedData => true;

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  bool get skipFullyLinkedData => false;

  @override
  bool get skipNonConstInitializers => false;

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Map<String, UnlinkedUnitBuilder> uriToUnit = this.uriToUnit;
    LinkerInputs linkerInputs = createLinkerInputs(text);
    linked = link(linkerInputs.linkedLibraries, linkerInputs.getDependency,
        linkerInputs.getUnit, strongMode)[linkerInputs.testDartUri.toString()];
    expect(linked, isNotNull);
    validateLinkedLibrary(linked);
    unlinkedUnits = <UnlinkedUnit>[linkerInputs.unlinkedDefiningUnit];
    for (String relativeUri
        in linkerInputs.unlinkedDefiningUnit.publicNamespace.parts) {
      UnlinkedUnit unit = uriToUnit[
          resolveRelativeUri(linkerInputs.testDartUri, Uri.parse(relativeUri))
              .toString()];
      if (unit == null) {
        if (!allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUri');
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
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit
   * passed to [addNamedSource].
   */
  Map<String, UnlinkedUnitBuilder> uriToUnit = <String, UnlinkedUnitBuilder>{};

  /**
   * Map from absolute URI to the [LinkedLibrary] for each compilation unit in a
   * package bundle passed to [addBundle].
   */
  Map<String, LinkedLibrary> _dependentLinkedLibraries =
      <String, LinkedLibrary>{};

  /**
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit in a
   * package bundle passed to [addBundle].
   */
  Map<String, UnlinkedUnit> _dependentUnlinkedUnits = <String, UnlinkedUnit>{};

  /**
   * A test will set this to `true` if it contains `import`, `export`, or
   * `part` declarations that deliberately refer to non-existent files.
   */
  bool get allowMissingFiles;

  /**
   * Add the given package bundle as a dependency so that it may be referenced
   * by the files under test.
   */
  void addBundle(PackageBundle bundle) {
    for (int i = 0; i < bundle.linkedLibraryUris.length; i++) {
      _dependentLinkedLibraries[bundle.linkedLibraryUris[i]] =
          bundle.linkedLibraries[i];
    }
    for (int i = 0; i < bundle.unlinkedUnitUris.length; i++) {
      _dependentUnlinkedUnits[bundle.unlinkedUnitUris[i]] =
          bundle.unlinkedUnits[i];
    }
  }

  /**
   * Add the given source file so that it may be referenced by the file under
   * test.
   */
  Source addNamedSource(String filePath, String contents) {
    CompilationUnit unit = _parseText(contents);
    UnlinkedUnitBuilder unlinkedUnit = serializeAstUnlinked(unit);
    uriToUnit[absUri(filePath)] = unlinkedUnit;
    // Tests using SummaryLinkerTest don't actually need the returned
    // Source, so we can safely return `null`.
    return null;
  }

  LinkerInputs createLinkerInputs(String text, {String path: '/test.dart'}) {
    Uri testDartUri = Uri.parse(absUri(path));
    CompilationUnit unit = _parseText(text);
    UnlinkedUnitBuilder unlinkedDefiningUnit = serializeAstUnlinked(unit);
    uriToUnit[testDartUri.toString()] = unlinkedDefiningUnit;
    LinkerInputs linkerInputs = new LinkerInputs(
        allowMissingFiles,
        uriToUnit,
        testDartUri,
        unlinkedDefiningUnit,
        _dependentLinkedLibraries,
        _dependentUnlinkedUnits);
    // Reset uriToUnit, _dependentLinkedLibraries, and _dependentUnlinkedUnits
    // in case the test needs to start a new package bundle.
    uriToUnit = <String, UnlinkedUnitBuilder>{};
    _dependentLinkedLibraries = <String, LinkedLibrary>{};
    _dependentUnlinkedUnits = <String, UnlinkedUnit>{};
    return linkerInputs;
  }

  /**
   * Link together the given file, along with any other files passed to
   * [addNamedSource], to form a package bundle.  Reset the state of the buffers
   * accumulated by [addNamedSource] and [addBundle] so that further bundles
   * can be created.
   */
  PackageBundleBuilder createPackageBundle(String text,
      {String path: '/test.dart'}) {
    PackageBundleAssembler assembler = new PackageBundleAssembler();
    LinkerInputs linkerInputs = createLinkerInputs(text, path: path);
    Map<String, LinkedLibraryBuilder> linkedLibraries = link(
        linkerInputs.linkedLibraries,
        linkerInputs.getDependency,
        linkerInputs.getUnit,
        true);
    linkedLibraries.forEach(assembler.addLinkedLibrary);
    linkerInputs._uriToUnit.forEach((String uri, UnlinkedUnitBuilder unit) {
      // Note: it doesn't matter what we store for the hash because it isn't
      // used in these tests.
      assembler.addUnlinkedUnitWithHash(uri, unit, 'HASH');
    });
    return assembler.assemble();
  }

  CompilationUnit _parseText(String text) {
    CharSequenceReader reader = new CharSequenceReader(text);
    Scanner scanner =
        new Scanner(null, reader, AnalysisErrorListener.NULL_LISTENER);
    Token token = scanner.tokenize();
    Parser parser = new Parser(null, AnalysisErrorListener.NULL_LISTENER);
    parser.parseGenericMethods = true;
    return parser.parseCompilationUnit(token);
  }
}
