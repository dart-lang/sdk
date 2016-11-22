// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';

/**
 * Search support for an [AnalysisDriver].
 */
class Search {
  final AnalysisDriver _driver;

  Search(this._driver);

  /**
   * Returns references to the [element].
   */
  Future<List<SearchResult>> references(Element element) async {
    if (element == null) {
      return const <SearchResult>[];
    }

    ElementKind kind = element.kind;
    if (kind == ElementKind.FUNCTION || kind == ElementKind.METHOD) {
      if (element.enclosingElement is ExecutableElement) {
        return _searchReferences_Local(element, (n) => n is Block);
      }
//      return _searchReferences_Function(element);
    } else if (kind == ElementKind.LABEL ||
        kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_Local(element, (n) => n is Block);
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_Local(
          element, (n) => n.parent is CompilationUnit);
    }
    // TODO(scheglov) support other kinds
    return const <SearchResult>[];
  }

  Future<List<SearchResult>> _searchReferences_Local(
      Element element, bool isRootNode(AstNode n)) async {
    String path = element.source.fullName;
    if (!_driver.addedFiles.contains(path)) {
      return const <SearchResult>[];
    }

    // Prepare the unit.
    AnalysisResult analysisResult = await _driver.getResult(path);
    CompilationUnit unit = analysisResult.unit;
    if (unit == null) {
      return const <SearchResult>[];
    }

    // Prepare the node.
    AstNode node = new NodeLocator(element.nameOffset).searchWithin(unit);
    if (node == null) {
      return const <SearchResult>[];
    }

    // Prepare the enclosing node.
    AstNode enclosingNode = node.getAncestor(isRootNode);
    if (enclosingNode == null) {
      return const <SearchResult>[];
    }

    // Find the matches.
    _LocalReferencesVisitor visitor =
        new _LocalReferencesVisitor(element, unit.element);
    enclosingNode.accept(visitor);
    return visitor.results;
  }
}

/**
 * A single search result.
 */
class SearchResult {
  /**
   * The element that is used at this result.
   */
  final Element element;

  /**
   * The deep most element that contains this result.
   */
  final Element enclosingElement;

  /**
   * The kind of the [element] usage.
   */
  final SearchResultKind kind;

  /**
   * The offset relative to the beginning of the containing file.
   */
  final int offset;

  /**
   * The length of the usage in the containing file context.
   */
  final int length;

  /**
   * Is `true` if a field or a method is using with a qualifier.
   */
  final bool isResolved;

  /**
   * Is `true` if the result is a resolved reference to [element].
   */
  final bool isQualified;

  SearchResult._(this.element, this.enclosingElement, this.kind, this.offset,
      this.length, this.isResolved, this.isQualified);

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("SearchResult(kind=");
    buffer.write(kind);
    buffer.write(", offset=");
    buffer.write(offset);
    buffer.write(", length=");
    buffer.write(length);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(", enclosingElement=");
    buffer.write(enclosingElement);
    buffer.write(")");
    return buffer.toString();
  }
}

/**
 * The kind of reference in a [SearchResult].
 */
enum SearchResultKind { READ, READ_WRITE, WRITE, INVOCATION, REFERENCE }

/**
 * A visitor that finds the deep-most [Element] that contains the [offset].
 */
class _ContainingElementFinder extends GeneralizingElementVisitor {
  final int offset;
  Element containingElement;

  _ContainingElementFinder(this.offset);

  visitElement(Element element) {
    if (element is ElementImpl) {
      if (element.codeOffset != null &&
          element.codeOffset <= offset &&
          offset <= element.codeOffset + element.codeLength) {
        containingElement = element;
        super.visitElement(element);
      }
    }
  }
}

/**
 * Visitor that adds [SearchResult]s for local elements of a block, method,
 * class or a library - labels, local functions, local variables and parameters,
 * type parameters, import prefixes.
 */
class _LocalReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchResult> results = <SearchResult>[];

  final Element element;
  final CompilationUnitElement enclosingUnitElement;

  _LocalReferencesVisitor(this.element, this.enclosingUnitElement);

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (node.staticElement == element) {
      AstNode parent = node.parent;
      SearchResultKind kind = SearchResultKind.REFERENCE;
      if (element is FunctionElement) {
        if (parent is MethodInvocation && parent.methodName == node) {
          kind = SearchResultKind.INVOCATION;
        }
      } else if (element is VariableElement) {
        bool isGet = node.inGetterContext();
        bool isSet = node.inSetterContext();
        if (isGet && isSet) {
          kind = SearchResultKind.READ_WRITE;
        } else if (isGet) {
          if (parent is MethodInvocation && parent.methodName == node) {
            kind = SearchResultKind.INVOCATION;
          } else {
            kind = SearchResultKind.READ;
          }
        } else if (isSet) {
          kind = SearchResultKind.WRITE;
        }
      }
      _addResult(node, kind);
    }
  }

  void _addResult(AstNode node, SearchResultKind kind) {
    bool isQualified = node.parent is Label;
    var finder = new _ContainingElementFinder(node.offset);
    enclosingUnitElement.accept(finder);
    results.add(new SearchResult._(element, finder.containingElement, kind,
        node.offset, node.length, true, isQualified));
  }
}
