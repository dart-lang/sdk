// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.navigation_dart;

import 'package:analysis_server/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A computer for navigation regions in a Dart [CompilationUnit].
 */
class DartNavigationComputer implements NavigationContributor {
  @override
  void computeNavigation(NavigationHolder holder, AnalysisContext context,
      Source source, int offset, int length) {
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.isNotEmpty) {
      CompilationUnit unit =
          context.getResolvedCompilationUnit2(source, libraries.first);
      if (unit != null) {
        _DartNavigationHolder dartHolder = new _DartNavigationHolder(holder);
        _DartNavigationComputerVisitor visitor =
            new _DartNavigationComputerVisitor(dartHolder);
        if (offset == null || length == null) {
          unit.accept(visitor);
        } else {
          _DartRangeAstVisitor partVisitor =
              new _DartRangeAstVisitor(offset, offset + length, visitor);
          unit.accept(partVisitor);
        }
      }
    }
  }
}

class _DartNavigationComputerVisitor extends RecursiveAstVisitor {
  final _DartNavigationHolder computer;

  _DartNavigationComputerVisitor(this.computer);

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    _safelyVisit(node.leftHandSide);
    computer._addRegionForToken(node.operator, node.bestElement);
    _safelyVisit(node.rightHandSide);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    _safelyVisit(node.leftOperand);
    computer._addRegionForToken(node.operator, node.bestElement);
    _safelyVisit(node.rightOperand);
  }

  @override
  visitCompilationUnit(CompilationUnit unit) {
    // prepare top-level nodes sorted by their offsets
    List<AstNode> nodes = <AstNode>[];
    nodes.addAll(unit.directives);
    nodes.addAll(unit.declarations);
    nodes.sort((a, b) {
      return a.offset - b.offset;
    });
    // visit sorted nodes
    for (AstNode node in nodes) {
      node.accept(this);
    }
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    // associate constructor with "T" or "T.name"
    {
      AstNode firstNode = node.returnType;
      AstNode lastNode = node.name;
      if (lastNode == null) {
        lastNode = firstNode;
      }
      if (firstNode != null && lastNode != null) {
        computer._addRegion_nodeStart_nodeEnd(
            firstNode, lastNode, node.element);
      }
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  visitConstructorName(ConstructorName node) {
    AstNode parent = node.parent;
    if (parent is InstanceCreationExpression &&
        parent.constructorName == node) {
      _addConstructorName(parent, node);
    } else if (parent is ConstructorDeclaration &&
        parent.redirectedConstructor == node) {
      _addConstructorName(node, node);
    }
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      Element libraryElement = exportElement.exportedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitExportDirective(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (importElement != null) {
      Element libraryElement = importElement.importedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitImportDirective(node);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    super.visitIndexExpression(node);
    computer._addRegionForToken(node.rightBracket, node.bestElement);
  }

  @override
  visitPartDirective(PartDirective node) {
    _addUriDirectiveRegion(node, node.element);
    super.visitPartDirective(node);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    computer._addRegion_tokenStart_nodeEnd(
        node.keyword, node.libraryName, node.element);
    super.visitPartOfDirective(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);
    computer._addRegionForToken(node.operator, node.bestElement);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    computer._addRegionForToken(node.operator, node.bestElement);
    super.visitPrefixExpression(node);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is ConstructorDeclaration) {
      return;
    }
    Element element = node.bestElement;
    computer._addRegionForNode(node, element);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    Element element = node.staticElement;
    if (element != null && element.isSynthetic) {
      element = element.enclosingElement;
    }
    // add region
    SimpleIdentifier name = node.constructorName;
    if (name != null) {
      computer._addRegion_nodeStart_nodeEnd(node, name, element);
    } else {
      computer._addRegionForToken(node.superKeyword, element);
    }
    // process arguments
    _safelyVisit(node.argumentList);
  }

  void _addConstructorName(AstNode parent, ConstructorName node) {
    Element element = node.staticElement;
    if (element == null) {
      return;
    }
    // if a synthetic constructor, navigate to the class
    if (element.isSynthetic) {
      element = element.enclosingElement;
    }
    // add regions
    TypeName typeName = node.type;
    computer._addRegionForNode(typeName.name, element);
    // <TypeA, TypeB>
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      typeArguments.accept(this);
    }
    // optional "name"
    if (node.name != null) {
      computer._addRegionForNode(node.name, element);
    }
  }

  /**
   * If the source of the given [element] (referenced by the [node]) exists,
   * then add the navigation region from the [node] to the [element].
   */
  void _addUriDirectiveRegion(UriBasedDirective node, Element element) {
    if (element != null) {
      Source source = element.source;
      if (element.context.exists(source)) {
        computer._addRegionForNode(node.uri, element);
      }
    }
  }

  void _safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}

/**
 * A Dart specific wrapper around [NavigationHolder].
 */
class _DartNavigationHolder {
  final NavigationHolder holder;

  _DartNavigationHolder(this.holder);

  void _addRegion(int offset, int length, Element element) {
    if (element is FieldFormalParameterElement) {
      element = (element as FieldFormalParameterElement).field;
    }
    if (element == null || element == DynamicElementImpl.instance) {
      return;
    }
    if (element.location == null) {
      return;
    }
    protocol.ElementKind kind =
        protocol.newElementKind_fromEngine(element.kind);
    protocol.Location location = protocol.newLocation_fromElement(element);
    if (location == null) {
      return;
    }
    holder.addRegion(offset, length, kind, location);
  }

  void _addRegion_nodeStart_nodeEnd(AstNode a, AstNode b, Element element) {
    int offset = a.offset;
    int length = b.end - offset;
    _addRegion(offset, length, element);
  }

  void _addRegion_tokenStart_nodeEnd(Token a, AstNode b, Element element) {
    int offset = a.offset;
    int length = b.end - offset;
    _addRegion(offset, length, element);
  }

  void _addRegionForNode(AstNode node, Element element) {
    int offset = node.offset;
    int length = node.length;
    _addRegion(offset, length, element);
  }

  void _addRegionForToken(Token token, Element element) {
    int offset = token.offset;
    int length = token.length;
    _addRegion(offset, length, element);
  }
}

/**
 * An AST visitor that forwards nodes intersecting with the range from
 * [start] to [end] to the given [visitor].
 */
class _DartRangeAstVisitor extends UnifyingAstVisitor {
  final int start;
  final int end;
  final AstVisitor visitor;

  _DartRangeAstVisitor(this.start, this.end, this.visitor);

  bool isInRange(int offset) {
    return start <= offset && offset <= end;
  }

  @override
  visitNode(AstNode node) {
    // The node ends before the range starts.
    if (node.end < start) {
      return;
    }
    // The node starts after the range ends.
    if (node.offset > end) {
      return;
    }
    // The node starts or ends in the range.
    if (isInRange(node.offset) || isInRange(node.end)) {
      node.accept(visitor);
      return;
    }
    // Go deeper.
    super.visitNode(node);
  }
}
