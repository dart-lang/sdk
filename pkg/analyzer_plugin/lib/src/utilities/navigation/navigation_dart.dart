// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/navigation/document_links.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';

NavigationCollector computeDartNavigation(
  ResourceProvider resourceProvider,
  NavigationCollector collector,
  ParsedUnitResult result,
  int? offset,
  int? length,
) {
  var dartCollector = _DartNavigationCollector(
    collector,
    resourceProvider,
    offset,
    length,
  );
  var unit = result.unit;
  var visitor = _DartNavigationComputerVisitor(
    resourceProvider: resourceProvider,
    computer: dartCollector,
    unit: result,
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
  var parent = current.parent;
  if (parent is FormalParameter) {
    current = parent;
  }

  // Consider the angle brackets for type arguments part of the leading type,
  // otherwise we don't navigate in the common situation of having the type name
  // selected, where VS Code provides the end of the selection as the position
  // to search.
  //
  // In `A^<String>` node will be TypeArgumentList and we will never find A if
  // we start visiting from there.
  if (current is TypeArgumentList && parent != null) {
    current = parent;
  }

  return current;
}

AstNode? _getNodeForRange(CompilationUnit unit, int offset, int length) {
  var node = unit.nodeCovering(offset: offset, length: length);
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
  final ResourceProvider resourceProvider;
  final int? requestedOffset;
  final int? requestedLength;

  _DartNavigationCollector(
    this.collector,
    this.resourceProvider,
    this.requestedOffset,
    this.requestedLength,
  );

  void _addRegion(
    int offset,
    int length,
    protocol.ElementKind kind,
    protocol.Location location, {
    Fragment? targetFragment,
  }) {
    // Discard elements that don't span the offset/range given (if provided).
    if (!_isWithinRequestedRange(offset, length)) {
      return;
    }

    collector.addRegion(
      offset,
      length,
      kind,
      location,
      targetFragment: targetFragment,
    );
  }

  void _addRegionForElement(SyntacticEntity? nodeOrToken, Element? element) {
    _addRegionForFragment(nodeOrToken, element?.nonSynthetic.firstFragment);
  }

  void _addRegionForFragment(SyntacticEntity? nodeOrToken, Fragment? fragment) {
    if (nodeOrToken == null || fragment == null) return;

    var offset = nodeOrToken.offset;
    var length = nodeOrToken.length;

    _addRegionForFragmentRange(offset, length, fragment);
  }

  void _addRegionForFragmentRange(
    int? offset,
    int? length,
    Fragment? fragment,
  ) {
    if (offset == null || length == null || fragment == null) return;

    if (fragment.element == DynamicElementImpl.instance) {
      return;
    }
    if (fragment.element is MultiplyDefinedElement) {
      return;
    }

    // Discard elements that don't span the offset/range given (if provided).
    if (!_isWithinRequestedRange(offset, length)) {
      return;
    }
    var location = fragment.toLocation();
    if (location == null) {
      return;
    }

    _addRegion(
      offset,
      length,
      fragment.toPluginElementKind,
      location,
      targetFragment: fragment,
    );
  }

  void _addRegionForLibrary(int offset, int length, String fullPath) {
    if (resourceProvider.getResource(fullPath).exists) {
      if (_isWithinRequestedRange(offset, length)) {
        collector.addRegion(
          offset,
          length,
          protocol.ElementKind.LIBRARY,
          protocol.Location(fullPath, 0, 0, 0, 0, endLine: 0, endColumn: 0),
        );
      }
    }
  }

  /// Checks if offset/length intersect with the range the user requested
  /// navigation regions for.
  ///
  /// If the request did not specify a range, always returns true.
  bool _isWithinRequestedRange(int offset, int length) {
    var requestedOffset = this.requestedOffset;
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
  final ParsedUnitResult unit;
  final DartDocumentLinkVisitor _documentLinkVisitor;
  final _DartNavigationCollector computer;

  _DartNavigationComputerVisitor({
    required this.resourceProvider,
    required this.unit,
    required this.computer,
  }) : _documentLinkVisitor = DartDocumentLinkVisitor(resourceProvider, unit);

  @override
  void visitAnnotation(Annotation node) {
    var element = node.element;
    if (element is ConstructorElement && element.isOriginImplicitDefault) {
      element = element.enclosingElement;
    }
    var name = node.name;
    if (name is PrefixedIdentifier) {
      // use constructor in: @PrefixClass.constructorName
      var prefixElement = name.prefix.element;
      if (prefixElement is ClassElement) {
        prefixElement = element;
      }
      computer._addRegionForElement(name.prefix, prefixElement);
      // always constructor
      computer._addRegionForElement(name.identifier, element);
    } else {
      computer._addRegionForElement(name, element);
    }
    computer._addRegionForElement(node.constructorName, element);
    // type arguments
    node.typeArguments?.accept(this);
    // arguments
    node.arguments?.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    computer._addRegionForElement(node.operator, node.element);
    node.rightHandSide.accept(this);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);
    computer._addRegionForElement(node.operator, node.element);
    node.rightOperand.accept(this);
  }

  @override
  void visitCatchClauseParameter(CatchClauseParameter node) {
    var fragment = node.declaredFragment;
    if (fragment == null) return;
    computer._addRegionForFragment(node.name, fragment);
    super.visitCatchClauseParameter(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    computer._addRegionForFragment(
      node.namePart.typeName,
      node.declaredFragment,
    );
    super.visitClassDeclaration(node);
  }

  @override
  void visitComment(Comment node) {
    super.visitComment(node);

    for (var link
        in _documentLinkVisitor
            .findLinks(node)
            .where((link) => link.targetUri.isScheme('file'))) {
      computer._addRegionForLibrary(
        link.offset,
        link.length,
        link.targetUri.toFilePath(),
      );
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
    var resolvedUri = node.resolvedUri;
    if (resolvedUri is DirectiveUriWithSource) {
      var source = resolvedUri.source;
      computer._addRegionForLibrary(
        node.uri.offset,
        node.uri.length,
        source.fullName,
      );
    }
    super.visitConfiguration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    node.metadata.accept(this);

    // For a default constructor, override the class name to be the declaration
    // itself rather than linking to the class.
    var nameToken = node.name;
    if (nameToken == null) {
      var constructorElement = node.declaredFragment?.element;
      computer._addRegionForElement(
        node.newKeyword ?? node.typeName,
        constructorElement,
      );
    } else {
      node.typeName?.accept(this);
      computer._addRegionForElement(
        node.newKeyword,
        node.declaredFragment?.element,
      );
      computer._addRegionForFragment(nameToken, node.declaredFragment);
    }

    node.parameters.accept(this);
    node.initializers.accept(this);
    node.redirectedConstructor?.accept(this);
    node.body.accept(this);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    Element? element = node.element;
    if (element == null) {
      return;
    }
    // add regions
    var namedType = node.type;
    // [prefix].ClassName
    {
      var importPrefix = namedType.importPrefix;
      if (importPrefix != null) {
        computer._addRegionForElement(importPrefix.name, importPrefix.element);
      }
      // For a named constructor, the class name points at the class.
      var classNameTargetElement = node.name != null
          ? namedType.element
          : element;
      computer._addRegionForElement(
        namedType.name,
        classNameTargetElement?.nonSynthetic,
      );
    }
    // <TypeA, TypeB>
    namedType.typeArguments?.accept(this);
    // optional "name"
    if (node.name != null) {
      computer._addRegionForElement(node.name, element);
    }
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (node.type == null) {
      var token = node.keyword;
      if (token != null && token.keyword == Keyword.VAR) {
        var inferredType = node.declaredFragment?.element.type;
        if (inferredType is InterfaceType) {
          computer._addRegionForElement(token, inferredType.element);
        }
      }
    }
    super.visitDeclaredIdentifier(node);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement case BindPatternVariableElement(:var join?)) {
      for (var variable in join.variables) {
        computer._addRegionForElement(node.name, variable);
      }
    } else {
      computer._addRegionForElement(node.name, declaredElement);
    }
    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    computer._addRegionForElement(node.name, node.constructorElement);

    var arguments = node.arguments;
    if (arguments != null) {
      computer._addRegionForElement(
        arguments.constructorSelector?.name,
        node.constructorElement,
      );
      arguments.typeArguments?.accept(this);
      arguments.argumentList.accept(this);
    }
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    computer._addRegionForFragment(
      node.namePart.typeName,
      node.declaredFragment,
    );
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _addUriDirectiveRegion(node, node.libraryExport?.uri);
    super.visitExportDirective(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    computer._addRegionForFragment(
      node.primaryConstructor.typeName,
      node.declaredFragment,
    );
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element != null) {
      computer._addRegionForElement(node.thisKeyword, element.field);
      computer._addRegionForElement(node.name, element.field);
    }

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _addUriDirectiveRegion(node, node.libraryImport?.uri);
    super.visitImportDirective(node);
  }

  @override
  void visitImportPrefixReference(ImportPrefixReference node) {
    var element = node.element;
    if (element == null) return;
    for (var fragment in element.fragments) {
      computer._addRegionForFragment(node.name, fragment);
    }
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    super.visitIndexExpression(node);
    var element = node.writeOrReadElement;
    computer._addRegionForElement(node.leftBracket, element);
    computer._addRegionForElement(node.rightBracket, element);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.element == null) {
      computer._addRegionForElement(
        node.constructorName,
        node.constructorName.type.element,
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    computer._addRegionForElement(node.name, node.element);
    super.visitLibraryDirective(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitMixinDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    node.importPrefix?.accept(this);
    computer._addRegionForElement(node.name, node.element);
    node.typeArguments?.accept(this);
  }

  @override
  void visitNameWithTypeParameters(NameWithTypeParameters node) {
    if (node.parent case ClassDeclaration declaration) {
      computer._addRegionForFragment(
        node.typeName,
        declaration.declaredFragment,
      );
    }
    if (node.parent case EnumDeclaration declaration) {
      computer._addRegionForFragment(
        node.typeName,
        declaration.declaredFragment,
      );
    }
    super.visitNameWithTypeParameters(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    var include = node.partInclude;
    if (include != null) {
      var uri = include.uri;
      if (uri is DirectiveUriWithUnit) {
        computer._addRegionForFragment(node.uri, uri.libraryFragment);
      } else if (uri is DirectiveUriWithSource) {
        var uriNode = node.uri;
        var source = uri.source;
        computer.collector.addRegion(
          uriNode.offset,
          uriNode.length,
          protocol.ElementKind.FILE,
          protocol.Location(
            source.fullName,
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

    super.visitPartDirective(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    var parentUnit = node.parent as CompilationUnit;
    var parentFragment = parentUnit.declaredFragment;
    computer._addRegionForFragment(
      node.libraryName ?? node.uri,
      parentFragment?.enclosingFragment,
    );

    super.visitPartOfDirective(node);
  }

  @override
  void visitPatternField(covariant PatternFieldImpl node) {
    var nameNode = node.name;
    if (nameNode != null) {
      var nameToken = nameNode.name ?? node.pattern.variablePattern?.name;
      if (nameToken != null) {
        computer._addRegionForElement(nameToken, node.element);
      }
    }

    node.pattern.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    super.visitPostfixExpression(node);
    computer._addRegionForElement(node.operator, node.element);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    computer._addRegionForElement(node.operator, node.element);
    super.visitPrefixExpression(node);
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    if (node.parent case Declaration declaration) {
      computer._addRegionForFragment(
        node.typeName,
        declaration.declaredFragment,
      );
    }
    super.visitPrimaryConstructorDeclaration(node);
  }

  @override
  void visitPrimaryConstructorName(PrimaryConstructorName node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      computer._addRegionForFragment(node.name, primary.declaredFragment);
    }
    super.visitPrimaryConstructorName(node);
  }

  @override
  void visitRedirectingConstructorInvocation(
    RedirectingConstructorInvocation node,
  ) {
    var element = node.element?.nonSynthetic;
    // add region
    computer._addRegionForElement(node.thisKeyword, element);
    computer._addRegionForElement(node.constructorName, element);
    // process arguments
    node.argumentList.accept(this);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var nameToken = node.name;
    if (nameToken != null) {
      computer._addRegionForFragment(nameToken, node.declaredFragment);
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.writeOrReadElement;
    if (element case PrefixElement(:var fragments, :var name)) {
      for (var fragment in fragments) {
        computer._addRegionForFragmentRange(
          node.offset,
          name?.length,
          fragment,
        );
      }
    } else if (element case JoinPatternVariableElement(:var variables)) {
      for (var variable in variables) {
        computer._addRegionForElement(node, variable);
      }
    } else {
      computer._addRegionForElement(node, element);
    }
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.element?.nonSynthetic;
    // add region
    computer._addRegionForElement(node.superKeyword, element);
    computer._addRegionForElement(node.constructorName, element);
    // process arguments
    node.argumentList.accept(this);
  }

  @override
  void visitSuperFormalParameter(SuperFormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element case SuperFormalParameterElementImpl element) {
      var superParameter = element.superConstructorParameter;
      computer._addRegionForElement(node.superKeyword, superParameter);
      computer._addRegionForElement(node.name, superParameter);
    }

    node.type?.accept(this);
    node.typeParameters?.accept(this);
    node.parameters?.accept(this);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitTypeParameter(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    computer._addRegionForFragment(node.name, node.declaredFragment);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    /// Return the element for the type inferred for each of the variables in
    /// the given list of [variables], or `null` if not all variable have the
    /// same inferred type.
    Element? getCommonElement(List<VariableDeclaration> variables) {
      var firstType = variables[0].declaredFragment?.element.type;
      if (firstType is! InterfaceType) {
        return null;
      }

      var firstElement = firstType.element;
      for (var i = 1; i < variables.length; i++) {
        var type = variables[i].declaredFragment?.element.type;
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
          computer._addRegionForElement(token!, element);
        }
      }
    }
    super.visitVariableDeclarationList(node);
  }

  /// If the [uri] references a value unit, then add the navigation region from
  /// the [node] to the unit.
  void _addUriDirectiveRegion(UriBasedDirective node, DirectiveUri? uri) {
    if (uri is DirectiveUriWithUnit && uri.source.exists()) {
      computer._addRegionForFragment(node.uri, uri.libraryFragment);
    } else if (uri is DirectiveUriWithLibrary && uri.source.exists()) {
      computer._addRegionForElement(node.uri, uri.library);
    }
  }
}

extension on Fragment {
  protocol.ElementKind get toPluginElementKind {
    // Preserve previous behaviour for compilation units, otherwise we will
    // show them all as LIBRARY (which is what their elements are).
    if (this is LibraryFragment && this != element.firstFragment) {
      return protocol.ElementKind.COMPILATION_UNIT;
    }
    return element.kind.toPluginElementKind;
  }

  /// Create a location based on this element.
  protocol.Location? toLocation({int? offset, int? length}) {
    var libraryFragment = this.libraryFragment;
    if (libraryFragment == null) {
      return null;
    }

    var nameOffset = this.nameOffset;
    var nameLength = name?.length;

    if (nameOffset == null) {
      // For default constructors, use the type name or new keyword as the
      // target location.
      if (this case ConstructorFragment self) {
        if (self.typeName != null) {
          nameOffset = self.typeNameOffset;
          nameLength = self.typeName?.length;
        } else if (self.newKeywordOffset != null) {
          nameOffset = self.newKeywordOffset;
          nameLength = 'new'.length;
        }
      }
    }

    if (nameLength != null && nameOffset != null) {
      offset ??= nameOffset;
      length ??= nameLength;
    } else {
      offset = 0;
      length = 0;
    }

    var lineInfo = libraryFragment.lineInfo;
    var offsetLocation = lineInfo.getLocation(offset);
    var endLocation = lineInfo.getLocation(offset + length);
    var startLine = offsetLocation.lineNumber;
    var startColumn = offsetLocation.columnNumber;
    var endLine = endLocation.lineNumber;
    var endColumn = endLocation.columnNumber;

    return protocol.Location(
      libraryFragment.source.fullName,
      offset,
      length,
      startLine,
      startColumn,
      endLine: endLine,
      endColumn: endColumn,
    );
  }
}
