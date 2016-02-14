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
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/prelink.dart';
import 'package:analyzer/src/summary/summarize_ast.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'summary_common.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(UnlinkedSummarizeAstTest);
}

/**
 * Override of [SummaryTest] which creates unlinked summaries directly from the
 * AST.
 */
@reflectiveTest
class UnlinkedSummarizeAstTest extends Object with SummaryTest {
  @override
  LinkedLibrary linked;

  @override
  List<UnlinkedUnit> unlinkedUnits;

  /**
   * Map from absolute URI to the [UnlinkedUnit] for each compilation unit
   * passed to [addNamedSource].
   */
  Map<String, UnlinkedUnit> uriToUnit = <String, UnlinkedUnit>{};

  @override
  bool get checkAstDerivedData => true;

  @override
  bool get expectAbsoluteUrisInDependencies => false;

  @override
  bool get skipFullyLinkedData => true;

  @override
  bool get strongMode => false;

  @override
  addNamedSource(String filePath, String contents) {
    CompilationUnit unit = _parseText(contents);
    UnlinkedUnit unlinkedUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    uriToUnit[absUri(filePath)] = unlinkedUnit;
  }

  @override
  void serializeLibraryText(String text, {bool allowErrors: false}) {
    Uri testDartUri = Uri.parse(absUri('/test.dart'));
    String resolveToAbsoluteUri(String relativeUri) =>
        testDartUri.resolve(relativeUri).toString();
    CompilationUnit unit = _parseText(text);
    UnlinkedUnit definingUnit =
        new UnlinkedUnit.fromBuffer(serializeAstUnlinked(unit).toBuffer());
    UnlinkedUnit getPart(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(relativeUri);
      UnlinkedUnit unit = uriToUnit[absoluteUri];
      if (unit == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested unit for "$relativeUri"'
            ' (resolves to "$absoluteUri").');
      }
      return unit;
    }
    UnlinkedPublicNamespace getImport(String relativeUri) {
      String absoluteUri = resolveToAbsoluteUri(relativeUri);
      UnlinkedPublicNamespace namespace = sdkPublicNamespace[absoluteUri];
      if (namespace == null) {
        namespace = uriToUnit[absoluteUri]?.publicNamespace;
      }
      if (namespace == null && !allowMissingFiles) {
        fail('Prelinker unexpectedly requested namespace for "$relativeUri"'
            ' (resolves to "$absoluteUri").'
            '  Namespaces available: ${uriToUnit.keys}');
      }
      return namespace;
    }
    linked = new LinkedLibrary.fromBuffer(
        prelink(definingUnit, getPart, getImport).toBuffer());
    validateLinkedLibrary(linked);
    unlinkedUnits = <UnlinkedUnit>[definingUnit];
    for (String relativeUri in definingUnit.publicNamespace.parts) {
      UnlinkedUnit unit = uriToUnit[resolveToAbsoluteUri(relativeUri)];
      if (unit == null) {
        if (!allowMissingFiles) {
          fail('Test referred to unknown unit $relativeUri');
        }
      } else {
        unlinkedUnits.add(unit);
      }
    }
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
