// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';

NavigationCollector computeDartNavigation(
    ResourceProvider resourceProvider,
    NavigationCollector collector,
    CompilationUnit unit,
    int offset,
    int length) {
  var dartCollector = _DartNavigationCollector(collector, offset, length);
  var visitor = _DartNavigationComputerVisitor(resourceProvider, dartCollector);
  if (offset == null || length == null) {
    unit.accept(visitor);
  } else {
    var node = _getNodeForRange(unit, offset, length);
    node?.accept(visitor);
  }
  return collector;
}

AstNode _getNodeForRange(CompilationUnit unit, int offset, int length) {
  var node = NodeLocator(offset, offset + length).searchWithin(unit);
  for (var n = node; n != null; n = n.parent) {
    if (n is Directive) {
      return n;
    }
  }
  return node;
}

/// A Dart specific wrapper around [NavigationCollector].
class _DartNavigationCollector {
  final NavigationCollector collector;
  final int requestedOffset;
  final int requestedLength;

  _DartNavigationCollector(
      this.collector, this.requestedOffset, this.requestedLength);

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
    // Discard elements that don't span the offset/range given (if provided).
    if (requestedOffset != null &&
        (offset > requestedOffset + (requestedLength ?? 0) ||
            offset + length < requestedOffset)) {
      return;
    }
    var converter = AnalyzerConverter();
    var kind = converter.convertElementKind(element.kind);
    var location = converter.locationFromElement(element);
    if (location == null) {
      return;
    }

    var codeLocation = collector.collectCodeLocations
        ? _getCodeLocation(element, location, converter)
        : null;

    collector.addRegion(offset, length, kind, location,
        targetCodeLocation: codeLocation);
  }

  void _addRegion_nodeStart_nodeEnd(AstNode a, AstNode b, Element element) {
    var offset = a.offset;
    var length = b.end - offset;
    _addRegion(offset, length, element);
  }

  void _addRegionForNode(AstNode node, Element element) {
    if (node == null) {
      return;
    }
    var offset = node.offset;
    var length = node.length;
    _addRegion(offset, length, element);
  }

  void _addRegionForToken(Token token, Element element) {
    var offset = token.offset;
    var length = token.length;
    _addRegion(offset, length, element);
  }

  /// Get the location of the code (excluding leading doc comments) for this element.
  protocol.Location _getCodeLocation(Element element,
      protocol.Location location, AnalyzerConverter converter) {
    var codeElement = element;
    // For synthetic getters created for fields, we need to access the associated
    // variable to get the codeOffset/codeLength.
    if (codeElement.isSynthetic && codeElement is PropertyAccessorElementImpl) {
      final variable = (codeElement as PropertyAccessorElementImpl).variable;
      if (variable is ElementImpl) {
        codeElement = variable as ElementImpl;
      }
    }

    // Read the main codeOffset from the element. This may include doc comments
    // but will give the correct end position.
    int codeOffset, codeLength;
    if (codeElement is ElementImpl) {
      codeOffset = codeElement.codeOffset;
      codeLength = codeElement.codeLength;
    }

    if (codeOffset == null || codeLength == null) {
      return null;
    }

    // Read the declaration so we can get the offset after the doc comments.
    // TODO(dantup): Skip this for parts (getParsedLibrary will throw), but find
    // a better solution.
    final declaration = !codeElement.session.getFile(location.file).isPart
        ? codeElement.session
            .getParsedLibrary(location.file)
            .getElementDeclaration(codeElement)
        : null;
    var node = declaration?.node;
    if (node is VariableDeclaration) {
      node = node.parent;
    }
    if (node is AnnotatedNode) {
      var offsetAfterDocs = node.firstTokenAfterCommentAndMetadata.offset;

      // Reduce the length by the difference between the end of docs and the start.
      codeLength -= (offsetAfterDocs - codeOffset);
      codeOffset = offsetAfterDocs;
    }

    if (codeOffset == null || codeLength == null) {
      return null;
    }

    return converter.locationFromElement(element,
        offset: codeOffset, length: codeLength);
  }
}

class _DartNavigationComputerVisitor extends RecursiveAstVisitor<void> {
  final ResourceProvider resourceProvider;
  final _DartNavigationCollector computer;

  _DartNavigationComputerVisitor(this.resourceProvider, this.computer);

  @override
  void visitAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement && element.isSynthetic) {
      element = element.enclosingElement;
    }
    var name = node.name;
    if (name is PrefixedIdentifier) {
      // use constructor in: @PrefixClass.constructorName
      var prefixElement = name.prefix.staticElement;
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
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide?.accept(this);
    computer._addRegionForToken(node.operator, node.staticElement);
    node.rightHandSide?.accept(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand?.accept(this);
    computer._addRegionForToken(node.operator, node.staticElement);
    node.rightOperand?.accept(this);
  }

  @override
  void visitCompilationUnit(CompilationUnit unit) {
    // prepare top-level nodes sorted by their offsets
    var nodes = <AstNode>[];
    nodes.addAll(unit.directives);
    nodes.addAll(unit.declarations);
    nodes.sort((a, b) {
      return a.offset - b.offset;
    });
    // visit sorted nodes
    for (var node in nodes) {
      node.accept(this);
    }
  }

  @override
  void visitConfiguration(Configuration node) {
    var source = node.uriSource;
    if (source != null) {
      if (resourceProvider.getResource(source.fullName).exists) {
        // TODO(brianwilkerson) If the analyzer ever resolves the URI to a
        //  library, use that library element to create the region.
        var uriNode = node.uri;
        computer.collector.addRegion(
            uriNode.offset,
            uriNode.length,
            protocol.ElementKind.LIBRARY,
            protocol.Location(source.fullName, 0, 0, 0, 0));
      }
    }
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // associate constructor with "T" or "T.name"
    {
      AstNode firstNode = node.returnType;
      AstNode lastNode = node.name;
      lastNode ??= firstNode;
      if (firstNode != null && lastNode != null) {
        computer._addRegion_nodeStart_nodeEnd(
            firstNode, lastNode, node.declaredElement);
      }
    }
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    var parent = node.parent;
    if (parent is InstanceCreationExpression &&
        parent.constructorName == node) {
      _addConstructorName(parent, node);
    } else if (parent is ConstructorDeclaration &&
        parent.redirectedConstructor == node) {
      _addConstructorName(node, node);
    }
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.type == null) {
      var token = node.keyword;
      if (token?.keyword == Keyword.VAR) {
        var inferredType = node.declaredElement?.type;
        var element = inferredType?.element;
        if (element != null) {
          computer._addRegionForToken(token, element);
        }
      }
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      Element libraryElement = exportElement.exportedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var importElement = node.element;
    if (importElement != null) {
      Element libraryElement = importElement.importedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    super.visitIndexExpression(node);
    var element = node.writeOrReadElement;
    computer._addRegionForToken(node.leftBracket, element);
    computer._addRegionForToken(node.rightBracket, element);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    computer._addRegionForNode(node.name, node.element);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _addUriDirectiveRegion(node, node.element);
    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    computer._addRegionForNode(node.libraryName, node.element);
    super.visitPartOfDirective(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);
    computer._addRegionForToken(node.operator, node.staticElement);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    computer._addRegionForToken(node.operator, node.staticElement);
    super.visitPrefixExpression(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
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
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is ConstructorDeclaration) {
      return;
    }
    var element = node.writeOrReadElement;
    computer._addRegionForNode(node, element);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
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
  void visitVariableDeclarationList(VariableDeclarationList node) {
    /// Return the element for the type inferred for each of the variables in
    /// the given list of [variables], or `null` if not all variable have the
    /// same inferred type.
    Element getCommonElement(List<VariableDeclaration> variables) {
      var firstElement = variables[0].declaredElement.type?.element;
      if (firstElement == null) {
        return null;
      }
      for (var i = 1; i < variables.length; i++) {
        var element = variables[1].declaredElement.type?.element;
        if (element != firstElement) {
          return null;
        }
      }
      return firstElement;
    }

    if (node.type == null) {
      var token = node.keyword;
      if (token?.keyword == Keyword.VAR) {
        var element = getCommonElement(node.variables);
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
    var typeName = node.type;
    // [prefix].ClassName
    {
      var name = typeName.name;
      var className = name;
      if (name is PrefixedIdentifier) {
        name.prefix.accept(this);
        className = name.identifier;
      }
      computer._addRegionForNode(className, element);
    }
    // <TypeA, TypeB>
    var typeArguments = typeName.typeArguments;
    if (typeArguments != null) {
      typeArguments.accept(this);
    }
    // optional "name"
    if (node.name != null) {
      computer._addRegionForNode(node.name, element);
    }
  }

  /// If the source of the given [element] (referenced by the [node]) exists,
  /// then add the navigation region from the [node] to the [element].
  void _addUriDirectiveRegion(UriBasedDirective node, Element element) {
    var source = element?.source;
    if (source != null) {
      if (resourceProvider.getResource(source.fullName).exists) {
        computer._addRegionForNode(node.uri, element);
      }
    }
  }
}
