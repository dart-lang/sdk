// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
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
    int? offset,
    int? length) {
  var dartCollector = _DartNavigationCollector(collector, offset, length);
  var visitor = _DartNavigationComputerVisitor(
    resourceProvider: resourceProvider,
    computer: dartCollector,
    unitElement: unit.declaredElement!,
  );
  if (offset == null || length == null) {
    unit.accept(visitor);
  } else {
    var node = _getNodeForRange(unit, offset, length);

    if (node != null) {
      node = _getNavigationTargetNode(node);
    }
    node?.accept(visitor);
  }
  return collector;
}

/// Gets the nearest node that should be used for navigation.
///
/// This is usually the outermost node with the same offset as node but in some
/// cases may be a different ancestor where required to produce the correct
/// result.
AstNode _getNavigationTargetNode(AstNode node) {
  AstNode? current = node;
  while (current != null &&
      current.parent != null &&
      current.offset == current.parent!.offset) {
    current = current.parent;
  }
  current ??= node;

  // To navigate to formal params, we need to visit the parameter and not just
  // the identifier but they don't start at the same offset as they have a
  // prefix.
  final parent = current.parent;
  if (parent is FormalParameter) {
    current = parent;
  }

  return current;
}

AstNode? _getNodeForRange(CompilationUnit unit, int offset, int length) {
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
  final int? requestedOffset;
  final int? requestedLength;

  _DartNavigationCollector(
      this.collector, this.requestedOffset, this.requestedLength);

  void _addRegion(
    int offset,
    int length,
    protocol.ElementKind kind,
    protocol.Location location, {
    Element? targetElement,
  }) {
    // Discard elements that don't span the offset/range given (if provided).
    if (!_isWithinRequestedRange(offset, length)) {
      return;
    }

    collector.addRegion(offset, length, kind, location,
        targetElement: targetElement);
  }

  void _addRegionForElement(int offset, int length, Element element) {
    element = element.nonSynthetic;
    if (element == DynamicElementImpl.instance) {
      return;
    }
    if (element.location == null) {
      return;
    }
    // Discard elements that don't span the offset/range given (if provided).
    if (!_isWithinRequestedRange(offset, length)) {
      return;
    }
    var location = element.toLocation();
    if (location == null) {
      return;
    }

    _addRegion(offset, length, element.kind.toPluginElementKind, location,
        targetElement: element);
  }

  void _addRegionForNode(AstNode? node, Element? element) {
    if (node == null || element == null) {
      return;
    }
    var offset = node.offset;
    var length = node.length;
    _addRegionForElement(offset, length, element);
  }

  void _addRegionForToken(Token token, Element? element) {
    if (element == null) {
      return;
    }
    var offset = token.offset;
    var length = token.length;
    _addRegionForElement(offset, length, element);
  }

  /// Checks if offset/length intersect with the range the user requested
  /// navigation regions for.
  ///
  /// If the request did not specify a range, always returns true.
  bool _isWithinRequestedRange(int offset, int length) {
    final requestedOffset = this.requestedOffset;
    if (requestedOffset == null) {
      return true;
    }
    if (offset > requestedOffset + (requestedLength ?? 0)) {
      // Starts after the requested range.
      return false;
    }
    if (offset + length < requestedOffset) {
      // Ends before the requested range.
      return false;
    }
    return true;
  }
}

class _DartNavigationComputerVisitor extends RecursiveAstVisitor<void> {
  final ResourceProvider resourceProvider;
  final CompilationUnitElement unitElement;
  final _DartNavigationCollector computer;

  /// The directory that contains `examples/api`, `null` if not found.
  late final Folder? folderWithExamplesApi = () {
    var filePath = unitElement.source.fullName;
    var file = resourceProvider.getFile(filePath);
    for (var parent in file.parent.withAncestors) {
      var apiFolder = parent
          .getChildAssumingFolder('examples')
          .getChildAssumingFolder('api');
      if (apiFolder.exists) {
        return parent;
      }
    }
    return null;
  }();

  _DartNavigationComputerVisitor({
    required this.resourceProvider,
    required this.unitElement,
    required this.computer,
  });

  @override
  void visitAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement && element.isSynthetic) {
      element = element.enclosingElement2;
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
    // type arguments
    node.typeArguments?.accept(this);
    // arguments
    node.arguments?.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    computer._addRegionForToken(node.operator, node.staticElement);
    node.rightHandSide.accept(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    computer._addRegionForToken(node.operator, node.staticElement);
    node.rightOperand.accept(this);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    computer._addRegionForToken(node.name, node.declaredElement);
    super.visitClassDeclaration(node);
  }

  @override
  void visitComment(Comment node) {
    if (!node.isDocumentation) {
      super.visitComment(node);
      return;
    }

    for (var commentReference in node.references) {
      commentReference.accept(this);
    }

    var inToolAnnotation = false;
    for (var token in node.tokens) {
      if (token.isEof) {
        break;
      }
      var strValue = token.toString();
      if (strValue.isEmpty) {
        continue;
      }

      if (inToolAnnotation) {
        if (strValue.contains('{@end-tool}')) {
          inToolAnnotation = false;
        } else {
          var seeCodeIn = '** See code in ';
          var startIndex = strValue.indexOf('${seeCodeIn}examples/api/');
          if (startIndex != -1) {
            final folderWithExamplesApi = this.folderWithExamplesApi;
            if (folderWithExamplesApi == null) {
              // Examples directory doesn't exist.
              super.visitComment(node);
              return;
            }
            startIndex += seeCodeIn.length;
            var endIndex = strValue.indexOf('.dart') + 5;
            var pathSnippet = strValue.substring(startIndex, endIndex);
            // Split on '/' because that's what the comment syntax uses, but
            // re-join it using the resource provider to get the right separator
            // for the platform.
            var examplePath = resourceProvider.pathContext.joinAll([
              folderWithExamplesApi.path,
              ...pathSnippet.split('/'),
            ]);
            var start = token.offset + startIndex;
            var end = token.offset + endIndex;
            computer._addRegion(
              start,
              end - start,
              protocol.ElementKind.LIBRARY,
              protocol.Location(
                examplePath,
                0,
                0,
                0,
                0,
                endLine: 0,
                endColumn: 0,
              ),
            );
          }
        }
      } else if (strValue.contains('{@tool ')) {
        inToolAnnotation = true;
      }
    }
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
    final resolvedUri = node.resolvedUri;
    if (resolvedUri is DirectiveUriWithSource) {
      final source = resolvedUri.source;
      if (resourceProvider.getResource(source.fullName).exists) {
        // TODO(brianwilkerson) If the analyzer ever resolves the URI to a
        //  library, use that library element to create the region.
        var uriNode = node.uri;
        if (computer._isWithinRequestedRange(uriNode.offset, uriNode.length)) {
          computer.collector.addRegion(
              uriNode.offset,
              uriNode.length,
              protocol.ElementKind.LIBRARY,
              protocol.Location(source.fullName, 0, 0, 0, 0,
                  endLine: 0, endColumn: 0));
        }
      }
    }
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // For a default constructor, override the class name to be the declaration
    // itself rather than linking to the class.
    var nameToken = node.name;
    if (nameToken == null) {
      computer._addRegionForNode(node.returnType, node.declaredElement);
    } else {
      node.returnType.accept(this);
      computer._addRegionForToken(nameToken, node.declaredElement);
    }
    node.parameters.accept(this);
    node.initializers.accept(this);
    node.redirectedConstructor?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    Element? element = node.staticElement;
    if (element == null) {
      return;
    }
    // add regions
    var namedType = node.type;
    // [prefix].ClassName
    {
      final importPrefix = namedType.importPrefix;
      if (importPrefix != null) {
        computer._addRegionForToken(importPrefix.name, importPrefix.element);
      }
      // For a named constructor, the class name points at the class.
      var classNameTargetElement =
          node.name != null ? namedType.element : element;
      computer._addRegionForToken(namedType.name2, classNameTargetElement);
    }
    // <TypeA, TypeB>
    namedType.typeArguments?.accept(this);
    // optional "name"
    if (node.name != null) {
      computer._addRegionForNode(node.name, element);
    }
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.type == null) {
      var token = node.keyword;
      if (token != null && token.keyword == Keyword.VAR) {
        var inferredType = node.declaredElement?.type;
        if (inferredType is InterfaceType) {
          computer._addRegionForToken(token, inferredType.element);
        }
      }
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    computer._addRegionForToken(node.name, node.constructorElement);

    var arguments = node.arguments;
    if (arguments != null) {
      computer._addRegionForNode(
        arguments.constructorSelector?.name,
        node.constructorElement,
      );
      arguments.typeArguments?.accept(this);
      arguments.argumentList.accept(this);
    }
  }

  @override
  void visitExportDirective(ExportDirective node) {
    var exportElement = node.element;
    if (exportElement != null) {
      var libraryElement = exportElement.exportedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitExportDirective(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    final element = node.declaredElement;
    if (element is FieldFormalParameterElementImpl) {
      computer._addRegionForToken(node.thisKeyword, element.field);
      computer._addRegionForToken(node.name, element.field);
    }

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    computer._addRegionForToken(node.name, node.declaredElement);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    var importElement = node.element;
    if (importElement != null) {
      var libraryElement = importElement.importedLibrary;
      _addUriDirectiveRegion(node, libraryElement);
    }
    super.visitImportDirective(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    computer._addRegionForToken(node.name, node.element);
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
    computer._addRegionForNode(node.name2, node.element);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    computer._addRegionForToken(node.name, node.declaredElement);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    node.importPrefix?.accept(this);
    computer._addRegionForToken(node.name2, node.element);
    node.typeArguments?.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    final element = node.element;
    if (element is PartElement) {
      final uri = element.uri;
      if (uri is DirectiveUriWithUnit) {
        computer._addRegionForNode(node.uri, uri.unit);
      } else if (uri is DirectiveUriWithSource) {
        final uriNode = node.uri;
        final source = uri.source;
        computer.collector.addRegion(
          uriNode.offset,
          uriNode.length,
          protocol.ElementKind.FILE,
          protocol.Location(source.fullName, 0, 0, 0, 0,
              endLine: 0, endColumn: 0),
        );
      }
    }

    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    computer._addRegionForNode(node.libraryName ?? node.uri, node.element);
    super.visitPartOfDirective(node);
  }

  @override
  void visitPatternField(covariant PatternFieldImpl node) {
    final nameNode = node.name;
    if (nameNode != null) {
      final nameToken = nameNode.name ?? node.pattern.variablePattern?.name;
      if (nameToken != null) {
        computer._addRegionForToken(nameToken, node.element);
      }
    }

    node.pattern.accept(this);
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
    Element? element = node.staticElement;
    if (element != null && element.isSynthetic) {
      element = element.enclosingElement2;
    }
    // add region
    computer._addRegionForToken(node.thisKeyword, element);
    computer._addRegionForNode(node.constructorName, element);
    // process arguments
    node.argumentList.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    final nameToken = node.name;
    if (nameToken != null) {
      computer._addRegionForToken(nameToken, node.declaredElement);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    computer._addRegionForNode(node, element);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    Element? element = node.staticElement;
    if (element != null && element.isSynthetic) {
      element = element.enclosingElement2;
    }
    // add region
    computer._addRegionForToken(node.superKeyword, element);
    computer._addRegionForNode(node.constructorName, element);
    // process arguments
    node.argumentList.accept(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    var element = node.declaredElement;
    if (element is SuperFormalParameterElementImpl) {
      var superParameter = element.superConstructorParameter;
      computer._addRegionForToken(node.superKeyword, superParameter);
      computer._addRegionForToken(node.name, superParameter);
    }

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    computer._addRegionForToken(node.name, node.declaredElement);
    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    computer._addRegionForToken(node.name, node.declaredElement);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    /// Return the element for the type inferred for each of the variables in
    /// the given list of [variables], or `null` if not all variable have the
    /// same inferred type.
    Element? getCommonElement(List<VariableDeclaration> variables) {
      final firstType = variables[0].declaredElement?.type;
      if (firstType is! InterfaceType) {
        return null;
      }

      var firstElement = firstType.element;
      for (var i = 1; i < variables.length; i++) {
        final type = variables[i].declaredElement?.type;
        if (type is! InterfaceType) {
          return null;
        }
        if (type.element != firstElement) {
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
          computer._addRegionForToken(token!, element);
        }
      }
    }
    super.visitVariableDeclarationList(node);
  }

  /// If the source of the given [element] (referenced by the [node]) exists,
  /// then add the navigation region from the [node] to the [element].
  void _addUriDirectiveRegion(UriBasedDirective node, LibraryElement? element) {
    var source = element?.source;
    if (source != null) {
      if (resourceProvider.getResource(source.fullName).exists) {
        computer._addRegionForNode(node.uri, element);
      }
    }
  }
}
