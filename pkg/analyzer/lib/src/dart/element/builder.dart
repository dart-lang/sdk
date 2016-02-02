// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.dart.element.builder;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the class `DirectiveElementBuilder` build elements for top
 * level library directives.
 */
class DirectiveElementBuilder extends SimpleAstVisitor<Object> {
  /**
   * The analysis context within which directive elements are being built.
   */
  final AnalysisContext context;

  /**
   * The library element for which directive elements are being built.
   */
  final LibraryElementImpl libraryElement;

  /**
   * Map from sources imported by this library to their corresponding library
   * elements.
   */
  final Map<Source, LibraryElement> importLibraryMap;

  /**
   * Map from sources imported by this library to their corresponding source
   * kinds.
   */
  final Map<Source, SourceKind> importSourceKindMap;

  /**
   * Map from sources exported by this library to their corresponding library
   * elements.
   */
  final Map<Source, LibraryElement> exportLibraryMap;

  /**
   * Map from sources exported by this library to their corresponding source
   * kinds.
   */
  final Map<Source, SourceKind> exportSourceKindMap;

  /**
   * The [ImportElement]s created so far.
   */
  final List<ImportElement> imports = <ImportElement>[];

  /**
   * The [ExportElement]s created so far.
   */
  final List<ExportElement> exports = <ExportElement>[];

  /**
   * The errors found while building directive elements.
   */
  final List<AnalysisError> errors = <AnalysisError>[];

  /**
   * Map from prefix names to their corresponding elements.
   */
  final HashMap<String, PrefixElementImpl> nameToPrefixMap =
      new HashMap<String, PrefixElementImpl>();

  /**
   * Indicates whether an explicit import of `dart:core` has been found.
   */
  bool explicitlyImportsCore = false;

  DirectiveElementBuilder(
      this.context,
      this.libraryElement,
      this.importLibraryMap,
      this.importSourceKindMap,
      this.exportLibraryMap,
      this.exportSourceKindMap);

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    //
    // Resolve directives.
    //
    for (Directive directive in node.directives) {
      directive.accept(this);
    }
    //
    // Ensure "dart:core" import.
    //
    Source librarySource = libraryElement.source;
    Source coreLibrarySource = context.sourceFactory.forUri(DartSdk.DART_CORE);
    if (!explicitlyImportsCore && coreLibrarySource != librarySource) {
      ImportElementImpl importElement = new ImportElementImpl(-1);
      importElement.importedLibrary = importLibraryMap[coreLibrarySource];
      importElement.synthetic = true;
      imports.add(importElement);
    }
    //
    // Populate the library element.
    //
    libraryElement.imports = imports;
    libraryElement.exports = exports;
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    Source exportedSource = node.source;
    if (exportedSource != null && context.exists(exportedSource)) {
      // The exported source will be null if the URI in the export
      // directive was invalid.
      LibraryElement exportedLibrary = exportLibraryMap[exportedSource];
      if (exportedLibrary != null) {
        ExportElementImpl exportElement = new ExportElementImpl(node.offset);
        StringLiteral uriLiteral = node.uri;
        if (uriLiteral != null) {
          exportElement.uriOffset = uriLiteral.offset;
          exportElement.uriEnd = uriLiteral.end;
        }
        exportElement.uri = node.uriContent;
        exportElement.combinators = _buildCombinators(node);
        exportElement.exportedLibrary = exportedLibrary;
        _setDoc(exportElement, node);
        node.element = exportElement;
        exports.add(exportElement);
        if (exportSourceKindMap[exportedSource] != SourceKind.LIBRARY) {
          errors.add(new AnalysisError(
              exportedSource,
              uriLiteral.offset,
              uriLiteral.length,
              CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
              [uriLiteral.toSource()]));
        }
      }
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    String uriContent = node.uriContent;
    if (DartUriResolver.isDartExtUri(uriContent)) {
      libraryElement.hasExtUri = true;
    }
    Source importedSource = node.source;
    if (importedSource != null && context.exists(importedSource)) {
      // The imported source will be null if the URI in the import
      // directive was invalid.
      LibraryElement importedLibrary = importLibraryMap[importedSource];
      if (importedLibrary != null) {
        if (importedLibrary.isDartCore) {
          explicitlyImportsCore = true;
        }
        ImportElementImpl importElement = new ImportElementImpl(node.offset);
        StringLiteral uriLiteral = node.uri;
        if (uriLiteral != null) {
          importElement.uriOffset = uriLiteral.offset;
          importElement.uriEnd = uriLiteral.end;
        }
        importElement.uri = uriContent;
        importElement.deferred = node.deferredKeyword != null;
        importElement.combinators = _buildCombinators(node);
        importElement.importedLibrary = importedLibrary;
        _setDoc(importElement, node);
        SimpleIdentifier prefixNode = node.prefix;
        if (prefixNode != null) {
          importElement.prefixOffset = prefixNode.offset;
          String prefixName = prefixNode.name;
          PrefixElementImpl prefix = nameToPrefixMap[prefixName];
          if (prefix == null) {
            prefix = new PrefixElementImpl.forNode(prefixNode);
            nameToPrefixMap[prefixName] = prefix;
          }
          importElement.prefix = prefix;
          prefixNode.staticElement = prefix;
        }
        node.element = importElement;
        imports.add(importElement);
        if (importSourceKindMap[importedSource] != SourceKind.LIBRARY) {
          ErrorCode errorCode = (importElement.isDeferred
              ? StaticWarningCode.IMPORT_OF_NON_LIBRARY
              : CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY);
          errors.add(new AnalysisError(importedSource, uriLiteral.offset,
              uriLiteral.length, errorCode, [uriLiteral.toSource()]));
        }
      }
    }
    return null;
  }

  /**
   * If the given [node] has a documentation comment, remember its content
   * and range into the given [element].
   */
  void _setDoc(ElementImpl element, AnnotatedNode node) {
    Comment comment = node.documentationComment;
    if (comment != null && comment.isDocumentation) {
      element.documentationComment =
          comment.tokens.map((Token t) => t.lexeme).join('\n');
      element.setDocRange(comment.offset, comment.length);
    }
  }

  /**
   * Build the element model representing the combinators declared by
   * the given [directive].
   */
  static List<NamespaceCombinator> _buildCombinators(
      NamespaceDirective directive) {
    _NamespaceCombinatorBuilder namespaceCombinatorBuilder =
        new _NamespaceCombinatorBuilder();
    for (Combinator combinator in directive.combinators) {
      combinator.accept(namespaceCombinatorBuilder);
    }
    return namespaceCombinatorBuilder.combinators;
  }
}

/**
 * Instances of the class [_NamespaceCombinatorBuilder] can be used to visit
 * [Combinator] AST nodes and generate [NamespaceCombinator] elements.
 */
class _NamespaceCombinatorBuilder extends SimpleAstVisitor<Object> {
  /**
   * Elements generated so far.
   */
  final List<NamespaceCombinator> combinators = <NamespaceCombinator>[];

  @override
  Object visitHideCombinator(HideCombinator node) {
    HideElementCombinatorImpl hide = new HideElementCombinatorImpl();
    hide.hiddenNames = _getIdentifiers(node.hiddenNames);
    combinators.add(hide);
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    ShowElementCombinatorImpl show = new ShowElementCombinatorImpl();
    show.offset = node.offset;
    show.end = node.end;
    show.shownNames = _getIdentifiers(node.shownNames);
    combinators.add(show);
    return null;
  }

  /**
   * Return the lexical identifiers associated with the given [identifiers].
   */
  static List<String> _getIdentifiers(NodeList<SimpleIdentifier> identifiers) {
    return identifiers.map((identifier) => identifier.name).toList();
  }
}
