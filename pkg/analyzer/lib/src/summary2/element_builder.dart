// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/link.dart';
import 'package:analyzer/src/summary2/reference.dart';

class ElementBuilder extends ThrowingAstVisitor<void> {
  final LibraryBuilder _libraryBuilder;
  final CompilationUnitElementImpl _unitElement;

  final _exports = <ExportElement>[];
  final _imports = <ImportElement>[];
  var _hasCoreImport = false;

  _EnclosingContext _enclosingContext;

  ElementBuilder({
    required LibraryBuilder libraryBuilder,
    required Reference unitReference,
    required CompilationUnitElementImpl unitElement,
  })  : _libraryBuilder = libraryBuilder,
        _unitElement = unitElement,
        _enclosingContext = _EnclosingContext(unitReference, unitElement);

  LibraryElementImpl get _libraryElement => _libraryBuilder.element;

  Linker get _linker => _libraryBuilder.linker;

  void buildDeclarationElements(CompilationUnit unit) {
    // TODO(scheglov) Use `unit.accept` when all nodes handled.
    for (var declaration in unit.declarations) {
      if (declaration is FunctionDeclaration ||
          declaration is TopLevelVariableDeclaration) {
        declaration.accept(this);
      }
    }
    _unitElement.accessors = _enclosingContext.propertyAccessors;
    _unitElement.functions = _enclosingContext.functions;
    _unitElement.topLevelVariables = _enclosingContext.properties
        .whereType<TopLevelVariableElementImpl>()
        .toList();
  }

  /// This method should be invoked after visiting directive nodes, it
  /// will set created exports and imports into [_libraryElement].
  void setExportsImports() {
    _libraryElement.exports = _exports;

    if (!_hasCoreImport) {
      var dartCore = _linker.elementFactory.libraryOfUri2('dart:core');
      _imports.add(
        ImportElementImpl(-1)
          ..importedLibrary = dartCore
          ..isSynthetic = true
          ..uri = 'dart:core',
      );
    }
    _libraryElement.imports = _imports;
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitExportDirective(covariant ExportDirectiveImpl node) {
    var element = ExportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.exportedLibrary = _selectLibrary(node);
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = node.uri.stringValue;

    node.element = element;
    _exports.add(element);
  }

  @override
  void visitFieldFormalParameter(
    covariant FieldFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultFieldFormalParameterElementImpl(name, nameOffset)
        ..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
    } else {
      element = FieldFormalParameterElementImpl(name, nameOffset);
      _linker.elementNodes[element] = node;
    }
    element.hasImplicitType = node.type == null;
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    element.parameterKind = node.kind;
    _setCodeRange(element, node);

    _enclosingContext.addParameter(element.name, element);
    nameNode.staticElement = element;

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        element.parameters = holder.parameters;
      }

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    node.parameters.accept(this);
  }

  @override
  void visitFunctionDeclaration(covariant FunctionDeclarationImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    var functionExpression = node.functionExpression;
    var body = functionExpression.body;

    Reference reference;
    ExecutableElementImpl executableElement;
    if (node.isGetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isGetter = true;

      reference = _enclosingContext.addGetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else if (node.isSetter) {
      var element = PropertyAccessorElementImpl(name, nameOffset);
      element.isSetter = true;

      reference = _enclosingContext.addSetter(name, element);
      executableElement = element;

      _buildSyntheticVariable(name: name, accessorElement: element);
    } else {
      var element = FunctionElementImpl(name, nameOffset);
      reference = _enclosingContext.addFunction(name, element);
      executableElement = element;
    }

    executableElement.hasImplicitReturnType = node.returnType == null;
    executableElement.isAsynchronous = body.isAsynchronous;
    executableElement.isExternal = node.externalKeyword != null;
    executableElement.isGenerator = body.isGenerator;
    executableElement.metadata = _buildAnnotations(node.metadata);
    _setCodeRange(executableElement, node);

    nameNode.staticElement = executableElement;
    _linker.elementNodes[executableElement] = node;

    var holder = _EnclosingContext(reference, executableElement);
    _withEnclosing(holder, () {
      var formalParameters = functionExpression.parameters;
      if (formalParameters != null) {
        formalParameters.accept(this);
        executableElement.parameters = holder.parameters;
      }

      var typeParameters = functionExpression.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        executableElement.typeParameters = holder.typeParameters;
      }
    });

    var localScope = _libraryBuilder.localScope;
    if (node.isSetter) {
      localScope.declare('$name=', reference);
    } else {
      localScope.declare(name, reference);
    }
  }

  @override
  void visitFunctionTypedFormalParameter(
    covariant FunctionTypedFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode.name;
    var nameOffset = nameNode.offset;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultParameterElementImpl(name, nameOffset)
        ..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
    } else {
      element = ParameterElementImpl(name, nameOffset);
      _linker.elementNodes[element] = node;
    }
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    element.parameterKind = node.kind;
    _setCodeRange(element, node);

    nameNode.staticElement = element;
    _linker.elementNodes[element] = node;
    _enclosingContext.addParameter(name, element);

    var fakeReference = Reference.root();
    var holder = _EnclosingContext(fakeReference, element);
    _withEnclosing(holder, () {
      var formalParameters = node.parameters;
      formalParameters.accept(this);
      element.parameters = holder.parameters;

      var typeParameters = node.typeParameters;
      if (typeParameters != null) {
        typeParameters.accept(this);
        element.typeParameters = holder.typeParameters;
      }
    });
  }

  @override
  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var element = ImportElementImpl(node.keyword.offset);
    element.combinators = _buildCombinators(node.combinators);
    element.importedLibrary = _selectLibrary(node);
    element.isDeferred = node.deferredKeyword != null;
    element.metadata = _buildAnnotations(node.metadata);
    element.uri = node.uri.stringValue;

    var prefixNode = node.prefix;
    if (prefixNode != null) {
      element.prefix = PrefixElementImpl(
        prefixNode.name,
        prefixNode.offset,
        reference: _libraryBuilder.reference
            .getChild('@prefix')
            .getChild(prefixNode.name),
      );
    }

    node.element = element;

    _imports.add(element);
    if (!_hasCoreImport) {
      if (node.uri.stringValue == 'dart:core') {
        _hasCoreImport = true;
      }
    }
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {}

  @override
  void visitPartDirective(PartDirective node) {}

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _libraryElement.hasPartOfDirective = true;
  }

  @override
  void visitSimpleFormalParameter(
    covariant SimpleFormalParameterImpl node,
  ) {
    var nameNode = node.identifier;
    var name = nameNode?.name ?? '';
    var nameOffset = nameNode?.offset ?? -1;

    ParameterElementImpl element;
    var parent = node.parent;
    if (parent is DefaultFormalParameter) {
      element = DefaultParameterElementImpl(name, nameOffset)
        ..constantInitializer = parent.defaultValue;
      _linker.elementNodes[element] = parent;
    } else {
      element = ParameterElementImpl(name, nameOffset);
      _linker.elementNodes[element] = node;
    }
    _enclosingContext.addParameter(element.name, element);

    element.hasImplicitType = node.type == null;
    element.isConst = node.isConst;
    element.isExplicitlyCovariant = node.covariantKeyword != null;
    element.isFinal = node.isFinal;
    element.metadata = _buildAnnotations(node.metadata);
    element.parameterKind = node.kind;
    _setCodeRange(element, node);

    node.declaredElement = element;
    nameNode?.staticElement = element;
  }

  @override
  void visitTopLevelVariableDeclaration(
    covariant TopLevelVariableDeclarationImpl node,
  ) {
    var enclosingRef = _enclosingContext.reference;

    for (var variable in node.variables.variables) {
      var nameNode = variable.name as SimpleIdentifierImpl;
      var name = nameNode.name;
      var nameOffset = nameNode.offset;

      TopLevelVariableElementImpl element;
      if (node.variables.isConst) {
        element = ConstTopLevelVariableElementImpl(name, nameOffset);
      } else {
        element = TopLevelVariableElementImpl(name, nameOffset);
      }

      element.hasInitializer = variable.initializer != null;
      element.isConst = node.variables.isConst;
      element.isExternal = node.externalKeyword != null;
      element.isFinal = node.variables.isFinal;
      element.isLate = node.variables.isLate;
      element.metadata = _buildAnnotations(node.metadata);

      if (node.variables.type == null) {
        element.hasImplicitType = true;
        element.type = DynamicTypeImpl.instance;
      }

      element.createImplicitAccessors(enclosingRef, name);

      _linker.elementNodes[element] = variable;
      _enclosingContext.addTopLevelVariable(name, element);
      nameNode.staticElement = element;

      var getter = element.getter;
      if (getter is PropertyAccessorElementImpl) {
        _enclosingContext.addGetter(name, getter);
        var localScope = _libraryBuilder.localScope;
        localScope.declare(name, getter.reference!);
      }

      var setter = element.setter;
      if (setter is PropertyAccessorElementImpl) {
        _enclosingContext.addSetter(name, setter);
        var localScope = _libraryBuilder.localScope;
        localScope.declare('$name=', setter.reference!);
      }
    }
  }

  @override
  void visitTypeParameter(covariant TypeParameterImpl node) {
    var nameNode = node.name;
    var name = nameNode.name;

    var element = TypeParameterElementImpl(name, nameNode.offset);
    element.metadata = _buildAnnotations(node.metadata);

    _linker.elementNodes[element] = node;
    _enclosingContext.addTypeParameter(name, element);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    node.typeParameters.accept(this);
  }

  List<ElementAnnotation> _buildAnnotations(
    List<Annotation> nodeList,
  ) {
    var length = nodeList.length;
    if (length == 0) {
      return const <ElementAnnotation>[];
    }

    var annotations = <ElementAnnotation>[];
    for (int i = 0; i < length; i++) {
      var ast = nodeList[i];
      annotations.add(ElementAnnotationImpl(_unitElement)
        ..annotationAst = ast
        ..element = ast.element);
    }
    return annotations;
  }

  void _buildSyntheticVariable({
    required String name,
    required PropertyAccessorElementImpl accessorElement,
  }) {
    var enclosingRef = _enclosingContext.reference;
    var isTopLevel = enclosingRef.isUnit;
    var containerName = isTopLevel ? '@variable' : '@field';
    var containerRef = enclosingRef.getChild(containerName);

    var propertyRef = containerRef.getChild(name);
    var property = propertyRef.element as PropertyInducingElementImpl?;
    if (property == null) {
      var variable = TopLevelVariableElementImpl(name, -1);
      variable.isSynthetic = true;
      variable.isFinal = accessorElement.isGetter;
      property = variable;
      _enclosingContext.addTopLevelVariable(name, variable);
    }

    accessorElement.variable = property;
    if (accessorElement.isGetter) {
      property.getter = accessorElement;
    } else {
      property.setter = accessorElement;
    }
  }

  Uri? _selectAbsoluteUri(NamespaceDirective directive) {
    var relativeUriStr = _selectRelativeUri(
      directive.configurations,
      directive.uri.stringValue,
    );
    if (relativeUriStr == null) {
      return null;
    }
    var relativeUri = Uri.parse(relativeUriStr);
    return resolveRelativeUri(_libraryBuilder.uri, relativeUri);
  }

  LibraryElement? _selectLibrary(NamespaceDirective node) {
    try {
      var uri = _selectAbsoluteUri(node);
      return _linker.elementFactory.libraryOfUri('$uri');
    } on FormatException {
      return null;
    }
  }

  String? _selectRelativeUri(
    List<Configuration> configurations,
    String? defaultUri,
  ) {
    for (var configuration in configurations) {
      var name = configuration.name.components.join('.');
      var value = configuration.value?.stringValue ?? 'true';
      if (_linker.declaredVariables.get(name) == value) {
        return configuration.uri.stringValue;
      }
    }
    return defaultUri;
  }

  /// Make the given [context] be the current one while running [f].
  void _withEnclosing(_EnclosingContext context, void Function() f) {
    var previousContext = _enclosingContext;
    _enclosingContext = context;
    try {
      f();
    } finally {
      _enclosingContext = previousContext;
    }
  }

  static List<NamespaceCombinator> _buildCombinators(
    List<Combinator> combinators,
  ) {
    return combinators.map((node) {
      if (node is HideCombinator) {
        return HideElementCombinatorImpl()
          ..hiddenNames = node.hiddenNames.nameList;
      }
      if (node is ShowCombinator) {
        return ShowElementCombinatorImpl()
          ..shownNames = node.shownNames.nameList;
      }
      throw UnimplementedError('${node.runtimeType}');
    }).toList();
  }

  static void _setCodeRange(ElementImpl element, AstNode node) {
    element.setCodeRange(node.offset, node.length);
  }
}

class _EnclosingContext {
  final Reference reference;
  final ElementImpl element;
  final List<FunctionElementImpl> functions = [];
  final List<ParameterElementImpl> parameters = [];
  final List<PropertyInducingElementImpl> properties = [];
  final List<PropertyAccessorElementImpl> propertyAccessors = [];
  final List<TypeParameterElementImpl> typeParameters = [];

  _EnclosingContext(this.reference, this.element);

  Reference addFunction(String name, FunctionElementImpl element) {
    functions.add(element);
    return _bindReference('@function', name, element);
  }

  Reference addGetter(String name, PropertyAccessorElementImpl element) {
    propertyAccessors.add(element);
    return _bindReference('@getter', name, element);
  }

  Reference? addParameter(String? name, ParameterElementImpl element) {
    parameters.add(element);
    if (name != null) {
      return _bindReference('@parameter', name, element);
    }
  }

  Reference addSetter(String name, PropertyAccessorElementImpl element) {
    propertyAccessors.add(element);
    return _bindReference('@setter', name, element);
  }

  Reference addTopLevelVariable(
      String name, TopLevelVariableElementImpl element) {
    properties.add(element);
    return _bindReference('@variable', name, element);
  }

  Reference addTypeParameter(String name, TypeParameterElementImpl element) {
    typeParameters.add(element);
    return _bindReference('@typeParameter', name, element);
  }

  Reference _bindReference(
    String containerName,
    String name,
    ElementImpl element,
  ) {
    var containerRef = this.reference.getChild(containerName);
    var reference = containerRef.getChild(name);
    reference.element = element;
    element.reference = reference;
    this.element.encloseElement(element);
    return reference;
  }
}

extension on Iterable<SimpleIdentifier> {
  List<String> get nameList {
    return map((e) => e.name).toList();
  }
}
