// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domains.analysis.navigation_dart;

import 'package:analysis_server/plugin/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/src/protocol_server.dart' as protocol;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

NavigationCollector computeDartNavigation(NavigationCollector collector,
    CompilationUnit unit, int offset, int length) {
  _DartNavigationCollector dartCollector =
      new _DartNavigationCollector(collector);
  _DartNavigationComputerVisitor visitor =
      new _DartNavigationComputerVisitor(dartCollector);
  if (offset == null || length == null) {
    unit.accept(visitor);
  } else {
    AstNode node = _getNodeForRange(unit, offset, length);
    node?.accept(visitor);
  }
  return collector;
}

AstNode _getNodeForRange(CompilationUnit unit, int offset, int length) {
  AstNode node = new NodeLocator(offset, offset + length).searchWithin(unit);
  for (AstNode n = node; n != null; n = n.parent) {
    if (n is Directive) {
      return n;
    }
  }
  return node;
}

/**
 * A computer for navigation regions in a Dart [CompilationUnit].
 */
class DartNavigationComputer implements NavigationContributor {
  @override
  void computeNavigation(NavigationCollector collector, AnalysisContext context,
      Source source, int offset, int length) {
    List<Source> libraries = context.getLibrariesContaining(source);
    if (libraries.isNotEmpty) {
      CompilationUnit unit =
          context.getResolvedCompilationUnit2(source, libraries.first);
      if (unit != null) {
        computeDartNavigation(collector, unit, offset, length);
      }
    }
  }
}

/**
 * A Dart specific wrapper around [NavigationCollector].
 */
class _DartNavigationCollector {
  final NavigationCollector collector;

  _DartNavigationCollector(this.collector);

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
    protocol.ElementKind kind = protocol.convertElementKind(element.kind);
    protocol.Location location = protocol.newLocation_fromElement(element);
    if (location == null) {
      return;
    }
    collector.addRegion(offset, length, kind, location);
  }

  void _addRegion_nodeStart_nodeEnd(AstNode a, AstNode b, Element element) {
    int offset = a.offset;
    int length = b.end - offset;
    _addRegion(offset, length, element);
  }

  void _addRegionForNode(AstNode node, Element element) {
    if (node == null) {
      return;
    }
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

class _DartNavigationComputerVisitor extends RecursiveAstVisitor {
  final _DartNavigationCollector computer;

  _DartNavigationComputerVisitor(this.computer);

  @override
  visitAnnotation(Annotation node) {
    Element element = node.element;
    if (element is ConstructorElement && element.isSynthetic) {
      element = element.enclosingElement;
    }
    Identifier name = node.name;
    if (name is PrefixedIdentifier) {
      // use constructor in: @PrefixClass.constructorName
      Element prefixElement = name.prefix.staticElement;
      if (prefixElement is ClassElement) {
        prefixElement = element;
      }
      computer._addRegionForNode(name.prefix, prefixElement);
      // always constructor
      computer._addRegionForNode(name.identifier, element);
    } else {
      computer._addRegionForNode(name, element);
    }
    computer._addRegionForNode(node.constructorName, element);
    // arguments
    node.arguments?.accept(this);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide?.accept(this);
    computer._addRegionForToken(node.operator, node.bestElement);
    node.rightHandSide?.accept(this);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    node.leftOperand?.accept(this);
    computer._addRegionForToken(node.operator, node.bestElement);
    node.rightOperand?.accept(this);
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
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.type == null) {
      Token token = node.keyword;
      if (token?.keyword == Keyword.VAR) {
        DartType inferredType = node.identifier?.bestType;
        Element element = inferredType?.element;
        if (element != null) {
          computer._addRegionForToken(token, element);
        }
      }
    }
    super.visitDeclaredIdentifier(node);
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
    MethodElement element = node.bestElement;
    computer._addRegionForToken(node.leftBracket, element);
    computer._addRegionForToken(node.rightBracket, element);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    computer._addRegionForNode(node.name, node.element);
  }

  @override
  visitPartDirective(PartDirective node) {
    _addUriDirectiveRegion(node, node.element);
    super.visitPartDirective(node);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    computer._addRegionForNode(node.libraryName, node.element);
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
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    Element element = node.staticElement;
    if (element != null && element.isSynthetic) {
      element = element.enclosingElement;
    }
    // add region
    computer._addRegionForToken(node.thisKeyword, element);
    computer._addRegionForNode(node.constructorName, element);
    // process arguments
    node.argumentList?.accept(this);
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
    computer._addRegionForToken(node.superKeyword, element);
    computer._addRegionForNode(node.constructorName, element);
    // process arguments
    node.argumentList?.accept(this);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    /**
     * Return the element for the type inferred for each of the variables in the
     * given list of [variables], or `null` if not all variable have the same
     * inferred type.
     */
    Element getCommonElement(List<VariableDeclaration> variables) {
      Element firstElement = variables[0].name?.bestType?.element;
      if (firstElement == null) {
        return null;
      }
      for (int i = 1; i < variables.length; i++) {
        Element element = variables[1].name?.bestType?.element;
        if (element != firstElement) {
          return null;
        }
      }
      return firstElement;
    }

    if (node.type == null) {
      Token token = node.keyword;
      if (token?.keyword == Keyword.VAR) {
        Element element = getCommonElement(node.variables);
        if (element != null) {
          computer._addRegionForToken(token, element);
        }
      }
    }
    super.visitVariableDeclarationList(node);
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
    // [prefix].ClassName
    {
      Identifier name = typeName.name;
      Identifier className = name;
      if (name is PrefixedIdentifier) {
        name.prefix.accept(this);
        className = name.identifier;
      }
      computer._addRegionForNode(className, element);
    }
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
}
