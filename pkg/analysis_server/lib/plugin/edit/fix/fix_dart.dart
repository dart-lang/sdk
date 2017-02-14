// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.edit.fix.fix_dart;

import 'dart:async';

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart'
    show DartFixContextImpl;
import 'package:analysis_server/src/services/correction/namespace.dart'
    show getExportedElement;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_context.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/task/dart.dart' show LIBRARY_ELEMENT4;

/**
 * Complete with top-level declarations with the given [name].
 */
typedef Future<List<TopLevelDeclarationInSource>> GetTopLevelDeclarations(
    String name);

/**
 * An object used to provide context information for [DartFixContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DartFixContext implements FixContext {
  /**
   * The provider for parsed or resolved ASTs.
   */
  AstProvider get astProvider;

  /**
   * The function to get top-level declarations from.
   */
  GetTopLevelDeclarations get getTopLevelDeclarations;

  /**
   * The [CompilationUnit] to compute fixes in.
   */
  CompilationUnit get unit;
}

/**
 * A [FixContributor] that can be used to contribute fixes for errors in Dart
 * files.
 *
 * Clients may extend this class when implementing plugins.
 */
abstract class DartFixContributor implements FixContributor {
  @override
  Future<List<Fix>> computeFixes(FixContext context) async {
    AnalysisContext analysisContext = context.analysisContext;
    Source source = context.error.source;
    if (!AnalysisEngine.isDartFileName(source.fullName)) {
      return Fix.EMPTY_LIST;
    }
    List<Source> libraries = analysisContext.getLibrariesContaining(source);
    if (libraries.isEmpty) {
      return Fix.EMPTY_LIST;
    }
    CompilationUnit unit =
        analysisContext.getResolvedCompilationUnit2(source, libraries[0]);
    if (unit == null) {
      return Fix.EMPTY_LIST;
    }
    DartFixContext dartContext = new DartFixContextImpl(
        context,
        _getTopLevelDeclarations(analysisContext),
        new AstProviderForContext(analysisContext),
        unit);
    return internalComputeFixes(dartContext);
  }

  /**
   * Return a list of fixes for the given [context].
   */
  Future<List<Fix>> internalComputeFixes(DartFixContext context);

  GetTopLevelDeclarations _getTopLevelDeclarations(AnalysisContext context) {
    return (String name) async {
      List<TopLevelDeclarationInSource> declarations = [];
      List<Source> librarySources = context.librarySources;
      for (Source librarySource in librarySources) {
        // Prepare the LibraryElement.
        LibraryElement libraryElement =
            context.getResult(librarySource, LIBRARY_ELEMENT4);
        if (libraryElement == null) {
          continue;
        }
        // Prepare the exported Element.
        Element element = getExportedElement(libraryElement, name);
        if (element == null) {
          continue;
        }
        if (element is PropertyAccessorElement) {
          element = (element as PropertyAccessorElement).variable;
        }
        // Add a new declaration.
        TopLevelDeclarationKind topLevelKind;
        if (element.kind == ElementKind.CLASS ||
            element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
          topLevelKind = TopLevelDeclarationKind.type;
        } else if (element.kind == ElementKind.FUNCTION) {
          topLevelKind = TopLevelDeclarationKind.function;
        } else if (element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
          topLevelKind = TopLevelDeclarationKind.variable;
        }
        if (topLevelKind != null) {
          bool isExported = element.librarySource != librarySource;
          declarations.add(new TopLevelDeclarationInSource(librarySource,
              new TopLevelDeclaration(topLevelKind, element.name), isExported));
        }
      }
      return declarations;
    };
  }
}
