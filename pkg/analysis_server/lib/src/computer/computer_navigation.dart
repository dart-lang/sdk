// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library computer.navigation;

import 'dart:collection';

import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/scanner.dart';


/**
 * A computer for navigation regions in a Dart [CompilationUnit].
 */
class DartUnitNavigationComputer {
  final CompilationUnit _unit;

  final List<String> files = <String>[];
  final Map<String, int> fileMap = new HashMap<String, int>();
  final List<protocol.NavigationTarget> targets = <protocol.NavigationTarget>[];
  final Map<Element, int> targetMap = new HashMap<Element, int>();
  final List<protocol.NavigationRegion> regions = <protocol.NavigationRegion>[];

  DartUnitNavigationComputer(this._unit);

  /**
   * Computes [regions], [targets] and [files].
   */
  void compute() {
    _unit.accept(new _DartUnitNavigationComputerVisitor(this));
  }

  int _addFile(String file) {
    int index = fileMap[file];
    if (index == null) {
      index = files.length;
      files.add(file);
      fileMap[file] = index;
    }
    return index;
  }

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
    int targetIndex = _addTarget(element);
    regions.add(
        new protocol.NavigationRegion(offset, length, <int>[targetIndex]));
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

  int _addTarget(Element element) {
    int index = targetMap[element];
    if (index == null) {
      index = targets.length;
      protocol.NavigationTarget target =
          protocol.newNavigationTarget_fromElement(element, _addFile);
      targets.add(target);
      targetMap[element] = index;
    }
    return index;
  }
}


class _DartUnitNavigationComputerVisitor extends RecursiveAstVisitor {
  final DartUnitNavigationComputer computer;

  _DartUnitNavigationComputerVisitor(this.computer);

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
            firstNode,
            lastNode,
            node.element);
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
      Element element = exportElement.exportedLibrary;
      computer._addRegion_tokenStart_nodeEnd(node.keyword, node.uri, element);
    }
    super.visitExportDirective(node);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportElement importElement = node.element;
    if (importElement != null) {
      Element element = importElement.importedLibrary;
      computer._addRegion_tokenStart_nodeEnd(node.keyword, node.uri, element);
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
    computer._addRegion_tokenStart_nodeEnd(
        node.keyword,
        node.uri,
        node.element);
    super.visitPartDirective(node);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    computer._addRegion_tokenStart_nodeEnd(
        node.keyword,
        node.libraryName,
        node.element);
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
      computer._addRegionForToken(node.keyword, element);
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
    TypeArgumentList typeArguments = typeName.typeArguments;
    if (typeArguments == null) {
      computer._addRegion_nodeStart_nodeEnd(parent, node, element);
    } else {
      computer._addRegion_nodeStart_nodeEnd(parent, typeName.name, element);
      // <TypeA, TypeB>
      typeArguments.accept(this);
      // optional ".name"
      if (node.period != null) {
        computer._addRegion_tokenStart_nodeEnd(node.period, node, element);
      }
    }
  }

  void _safelyVisit(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}
