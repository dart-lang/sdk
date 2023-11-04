// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:collection/collection.dart';

class ClassDeclarationImpl extends macro.ClassDeclarationImpl {
  late final ClassElement element;

  ClassDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.interfaces,
    required super.hasAbstract,
    required super.hasBase,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasInterface,
    required super.hasMixin,
    required super.hasSealed,
    required super.mixins,
    required super.superclass,
  });
}

class DeclarationBuilder {
  final ast.AstNode? Function(Element?) nodeOfElement;

  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();
  final Map<Uri, List<ast.Annotation>> libraryMetadataMap = {};

  late final DeclarationBuilderFromNode fromNode =
      DeclarationBuilderFromNode(this);

  late final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement(this);

  /// The annotations that were recognized as macro applications.
  final Set<ast.Annotation> macroAnnotations = {};

  DeclarationBuilder({
    required this.nodeOfElement,
  });
}

class DeclarationBuilderFromElement {
  final DeclarationBuilder declarationBuilder;

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  final Map<ClassElement, IntrospectableClassDeclarationImpl> _classMap =
      Map.identity();

  final Map<MixinElement, IntrospectableMixinDeclarationImpl> _mixinMap =
      Map.identity();

  final Map<FieldElement, FieldDeclarationImpl> _fieldMap = Map.identity();

  final Map<ExecutableElement, MethodDeclarationImpl> _methodMap =
      Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterDeclarationImpl>
      _typeParameterMap = Map.identity();

  DeclarationBuilderFromElement(this.declarationBuilder);

  macro.IntrospectableClassDeclarationImpl classElement(ClassElement element) {
    return _classMap[element] ??= _introspectableClassElement(element);
  }

  macro.FieldDeclarationImpl fieldElement(FieldElement element) {
    return _fieldMap[element] ??= _fieldElement(element);
  }

  macro.IdentifierImpl identifier(Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: element.name!,
      element: element,
    );
  }

  macro.LibraryImpl library(Element element) {
    var library = _libraryMap[element.library];
    if (library == null) {
      final version = element.library!.languageVersion.effective;
      library = LibraryImplFromElement(
          id: macro.RemoteInstance.uniqueId,
          languageVersion:
              macro.LanguageVersionImpl(version.major, version.minor),
          metadata: _buildMetadata(element),
          uri: element.library!.source.uri,
          element: element);
      _libraryMap[element.library!] = library;
    }
    return library;
  }

  macro.MethodDeclarationImpl methodElement(MethodElement element) {
    return _methodMap[element] ??= _methodElement(element);
  }

  macro.IntrospectableMixinDeclarationImpl mixinElement(MixinElement element) {
    return _mixinMap[element] ??= _introspectableMixinElement(element);
  }

  macro.TypeParameterDeclarationImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    // TODO: Provide metadata annotations.
    return const [];
  }

  macro.TypeAnnotationImpl _dartType(DartType type) {
    switch (type) {
      case InterfaceType():
        return _interfaceType(type);
      case TypeParameterType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
          identifier: identifier(type.element),
          typeArguments: const [],
        );
      case VoidType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: macro.IdentifierImpl(
            id: macro.RemoteInstance.uniqueId,
            name: 'void',
          ),
          isNullable: false,
          typeArguments: const [],
        );
      default:
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  FieldDeclarationImpl _fieldElement(FieldElement element) {
    final enclosingElement = element.enclosingElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasLate: element.isLate,
      type: _dartType(element.type),
      definingType: identifier(enclosingElement),
      isStatic: element.isStatic,
    );
  }

  macro.NamedTypeAnnotationImpl _interfaceType(InterfaceType type) {
    return macro.NamedTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      identifier: identifier(type.element),
      typeArguments: type.typeArguments.map(_dartType).toList(),
    );
  }

  IntrospectableClassDeclarationImpl _introspectableClassElement(
      ClassElement element) {
    return IntrospectableClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      interfaces: element.interfaces.map(_interfaceType).toList(),
      hasAbstract: element.isAbstract,
      hasBase: element.isBase,
      hasExternal: false,
      hasFinal: element.isFinal,
      hasInterface: element.isInterface,
      hasMixin: element.isMixinClass,
      hasSealed: element.isSealed,
      mixins: element.mixins.map(_interfaceType).toList(),
      superclass: element.supertype.mapOrNull(_interfaceType),
      element: element,
    );
  }

  IntrospectableMixinDeclarationImpl _introspectableMixinElement(
      MixinElement element) {
    return IntrospectableMixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      hasBase: element.isBase,
      interfaces: element.interfaces.map(_interfaceType).toList(),
      superclassConstraints:
          element.superclassConstraints.map(_interfaceType).toList(),
      element: element,
    );
  }

  MethodDeclarationImpl _methodElement(MethodElement element) {
    final enclosingClass = element.enclosingElement as ClassElement;
    return MethodDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: false,
      // hasBody: node.body is! ast.EmptyFunctionBody,
      hasBody: true,
      // hasExternal: node.externalKeyword != null,
      hasExternal: false,
      // isGetter: node.isGetter,
      isGetter: false,
      // isOperator: node.isOperator,
      isOperator: false,
      // isSetter: node.isSetter,
      isSetter: false,
      // isStatic: node.isStatic,
      isStatic: element.isStatic,
      namedParameters: [], // TODO(scheglov) implement
      positionalParameters: [], // TODO(scheglov) implement
      returnType: _dartType(element.returnType),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      definingType: identifier(enclosingClass),
    );
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    TypeParameterElement element,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      bound: element.bound.mapOrNull(_dartType),
    );
  }
}

class DeclarationBuilderFromNode {
  final DeclarationBuilder declarationBuilder;

  final Map<ast.NamedType, IdentifierImpl> _namedTypeMap = Map.identity();

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  DeclarationBuilderFromNode(this.declarationBuilder);

  macro.ClassDeclarationImpl classDeclaration(
    ast.ClassDeclaration node,
  ) {
    return _introspectableClassDeclaration(node);
  }

  macro.LibraryImpl library(Element element) {
    final library = element.library!;

    if (_libraryMap[library] case final result?) {
      return result;
    }

    final version = library.languageVersion.effective;
    final uri = library.source.uri;
    final metadataNodes = declarationBuilder.libraryMetadataMap[uri] ?? [];

    return _libraryMap[library] = LibraryImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      languageVersion: macro.LanguageVersionImpl(
        version.major,
        version.minor,
      ),
      metadata: _buildMetadata(metadataNodes),
      uri: uri,
      element: library,
    );
  }

  macro.MethodDeclarationImpl methodDeclaration(
    ast.MethodDeclaration node,
  ) {
    return _methodDeclaration(node);
  }

  macro.MixinDeclarationImpl mixinDeclaration(
    ast.MixinDeclaration node,
  ) {
    return _introspectableMixinDeclaration(node);
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(
    List<ast.Annotation> nodes,
  ) {
    return nodes
        .whereNot(declarationBuilder.macroAnnotations.contains)
        .map(_buildMetadataNode)
        .whereNotNull()
        .toList();
  }

  macro.MetadataAnnotationImpl? _buildMetadataNode(
    ast.Annotation node,
  ) {
    final unitNode = node.thisOrAncestorOfType<ast.CompilationUnit>()!;
    final unitElement = unitNode.declaredElement!;
    final libraryElement = unitElement.library;
    final importPrefixNames = libraryElement.libraryImports
        .map((e) => e.prefix?.element.name)
        .whereNotNull()
        .toSet();

    final identifiers = <ast.SimpleIdentifier>[];

    switch (node.name) {
      case ast.PrefixedIdentifier node:
        identifiers.add(node.prefix);
        identifiers.add(node.identifier);
      case ast.SimpleIdentifier node:
        identifiers.add(node);
      default:
        return null;
    }

    identifiers.addIfNotNull(node.constructorName);

    var nextIndex = 0;
    if (importPrefixNames.contains(identifiers.first.name)) {
      nextIndex++;
    }

    final identifierName = identifiers[nextIndex++];
    final constructorName = identifiers.elementAtOrNull(nextIndex);

    final arguments = node.arguments;
    if (arguments != null) {
      return macro.ConstructorMetadataAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        constructor: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: constructorName?.name ?? '',
          getElement: () => node.element,
        ),
        type: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: identifierName.name,
          getElement: () => identifierName.staticElement,
        ),
      );
    }

    return macro.IdentifierMetadataAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: IdentifierImplFromNode(
        id: macro.RemoteInstance.uniqueId,
        name: identifierName.name,
        getElement: () => identifierName.staticElement,
      ),
    );
  }

  macro.IdentifierImpl _declaredIdentifier(Token name, Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name.lexeme,
      element: element,
    );
  }

  macro.IdentifierImpl _definingType(ast.AstNode node) {
    final parentNode = node.parent;
    switch (parentNode) {
      case ast.ClassDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.MixinDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      default:
        // TODO(scheglov) other parents
        throw UnimplementedError('(${parentNode.runtimeType}) $parentNode');
    }
  }

  macro.ParameterDeclarationImpl _formalParameter(ast.FormalParameter node) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotation(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    final element = node.declaredElement!;

    return macro.ParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name!, element),
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      library: library(element),
      metadata: _buildMetadata(node.metadata),
      type: typeAnnotation,
    );
  }

  macro.FunctionTypeParameterImpl _functionTypeFormalParameter(
    ast.FormalParameter node,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotation(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      metadata: _buildMetadata(node.metadata),
      name: node.name?.lexeme,
      type: typeAnnotation,
    );
  }

  IntrospectableClassDeclarationImpl _introspectableClassDeclaration(
    ast.ClassDeclaration node,
  ) {
    final element = node.declaredElement as ClassElementImpl;

    final interfaceNodes = <ast.NamedType>[];
    final mixinNodes = <ast.NamedType>[];
    for (var current = node;;) {
      if (current.implementsClause case final clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      if (current.withClause case final clause?) {
        mixinNodes.addAll(clause.mixinTypes);
      }
      final nextElement = current.declaredElement?.augmentation;
      final nextNode = declarationBuilder.nodeOfElement(nextElement);
      if (nextNode is! ast.ClassDeclaration) {
        break;
      }
      current = nextNode;
    }

    return IntrospectableClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(node.metadata),
      typeParameters: _typeParameters(node.typeParameters),
      interfaces: _namedTypes(interfaceNodes),
      hasAbstract: node.abstractKeyword != null,
      hasBase: node.baseKeyword != null,
      hasExternal: false,
      hasFinal: node.finalKeyword != null,
      hasInterface: node.interfaceKeyword != null,
      hasMixin: node.mixinKeyword != null,
      hasSealed: node.sealedKeyword != null,
      mixins: _namedTypes(mixinNodes),
      superclass: node.extendsClause?.superclass.mapOrNull(_namedType),
      element: element,
    );
  }

  IntrospectableMixinDeclarationImpl _introspectableMixinDeclaration(
    ast.MixinDeclaration node,
  ) {
    final element = node.declaredElement as MixinElementImpl;

    final onNodes = <ast.NamedType>[];
    final interfaceNodes = <ast.NamedType>[];
    for (var current = node;;) {
      if (current.onClause case final clause?) {
        onNodes.addAll(clause.superclassConstraints);
      }
      if (current.implementsClause case final clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      final nextElement = current.declaredElement?.augmentation;
      final nextNode = declarationBuilder.nodeOfElement(nextElement);
      if (nextNode is! ast.MixinDeclaration) {
        break;
      }
      current = nextNode;
    }

    return IntrospectableMixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(node.metadata),
      typeParameters: _typeParameters(node.typeParameters),
      hasBase: node.baseKeyword != null,
      interfaces: _namedTypes(interfaceNodes),
      superclassConstraints: _namedTypes(onNodes),
      element: element,
    );
  }

  MethodDeclarationImpl _methodDeclaration(
    ast.MethodDeclaration node,
  ) {
    final definingType = _definingType(node);
    final element = node.declaredElement!;

    return MethodDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(node.metadata),
      hasAbstract: false,
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isOperator: node.isOperator,
      isSetter: node.isSetter,
      isStatic: node.isStatic,
      namedParameters: _namedFormalParameters(node.parameters),
      positionalParameters: _positionalFormalParameters(node.parameters),
      returnType: _typeAnnotation(node.returnType),
      typeParameters: _typeParameters(node.typeParameters),
    );
  }

  List<macro.ParameterDeclarationImpl> _namedFormalParameters(
    ast.FormalParameterList? node,
  ) {
    if (node != null) {
      return node.parameters
          .where((e) => e.isNamed)
          .map(_formalParameter)
          .toList();
    } else {
      return const [];
    }
  }

  macro.NamedTypeAnnotationImpl _namedType(ast.NamedType node) {
    return macro.NamedTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _namedTypeIdentifier(node),
      isNullable: node.question != null,
      typeArguments: _typeAnnotations(node.typeArguments?.arguments),
    );
  }

  macro.IdentifierImpl _namedTypeIdentifier(ast.NamedType node) {
    return _namedTypeMap[node] ??= _NamedTypeIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: node.name2.lexeme,
      node: node,
    );
  }

  List<macro.NamedTypeAnnotationImpl> _namedTypes(
    List<ast.NamedType>? elements,
  ) {
    if (elements != null) {
      return elements.map(_namedType).toList();
    } else {
      return const [];
    }
  }

  List<macro.ParameterDeclarationImpl> _positionalFormalParameters(
    ast.FormalParameterList? node,
  ) {
    if (node != null) {
      return node.parameters
          .where((e) => e.isPositional)
          .map(_formalParameter)
          .toList();
    } else {
      return const [];
    }
  }

  macro.TypeAnnotationImpl _typeAnnotation(ast.TypeAnnotation? node) {
    switch (node) {
      case null:
        return macro.OmittedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
        );
      case ast.GenericFunctionType():
        return macro.FunctionTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: node.question != null,
          namedParameters: node.parameters.parameters
              .where((e) => e.isNamed)
              .map(_functionTypeFormalParameter)
              .toList(),
          positionalParameters: node.parameters.parameters
              .where((e) => e.isPositional)
              .map(_functionTypeFormalParameter)
              .toList(),
          returnType: _typeAnnotation(node.returnType),
          typeParameters: _typeParameters(node.typeParameters),
        );
      case ast.NamedType():
        return _namedType(node);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  List<macro.TypeAnnotationImpl> _typeAnnotations(
    List<ast.TypeAnnotation>? elements,
  ) {
    if (elements != null) {
      return List.generate(
          elements.length, (i) => _typeAnnotation(elements[i]));
    } else {
      return const [];
    }
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, node.declaredElement!),
      library: library(node.declaredElement!),
      metadata: _buildMetadata(node.metadata),
      bound: node.bound.mapOrNull(_typeAnnotation),
    );
  }

  List<macro.TypeParameterDeclarationImpl> _typeParameters(
    ast.TypeParameterList? typeParameterList,
  ) {
    if (typeParameterList != null) {
      return typeParameterList.typeParameters.map(_typeParameter).toList();
    } else {
      return const [];
    }
  }
}

class FieldDeclarationImpl extends macro.FieldDeclarationImpl {
  FieldDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasLate,
    required super.type,
    required super.definingType,
    required super.isStatic,
  });
}

abstract class IdentifierImpl extends macro.IdentifierImpl {
  IdentifierImpl({
    required super.id,
    required super.name,
  });

  Element? get element;
}

class IdentifierImplFromElement extends IdentifierImpl {
  @override
  final Element element;

  IdentifierImplFromElement({
    required super.id,
    required super.name,
    required this.element,
  });
}

class IdentifierImplFromNode extends IdentifierImpl {
  final Element? Function() getElement;

  IdentifierImplFromNode({
    required super.id,
    required super.name,
    required this.getElement,
  });

  @override
  Element? get element => getElement();
}

class IntrospectableClassDeclarationImpl
    extends macro.IntrospectableClassDeclarationImpl {
  final ClassElement element;

  IntrospectableClassDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.interfaces,
    required super.hasAbstract,
    required super.hasBase,
    required super.hasFinal,
    required super.hasExternal,
    required super.hasInterface,
    required super.hasMixin,
    required super.hasSealed,
    required super.mixins,
    required super.superclass,
    required this.element,
  });
}

class IntrospectableMixinDeclarationImpl
    extends macro.IntrospectableMixinDeclarationImpl {
  final MixinElement element;

  IntrospectableMixinDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.hasBase,
    required super.interfaces,
    required super.superclassConstraints,
    required this.element,
  });
}

abstract class LibraryImpl extends macro.LibraryImpl {
  LibraryImpl({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
  });

  Element? get element;
}

class LibraryImplFromElement extends LibraryImpl {
  @override
  final Element element;

  LibraryImplFromElement({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
    required this.element,
  });
}

class MethodDeclarationImpl extends macro.MethodDeclarationImpl {
  final ExecutableElement element;

  MethodDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasAbstract,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.isStatic,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required super.definingType,
    required this.element,
  });
}

class _DeclaredIdentifierImpl extends IdentifierImpl {
  @override
  final Element element;

  _DeclaredIdentifierImpl({
    required super.id,
    required super.name,
    required this.element,
  });
}

class _NamedTypeIdentifierImpl extends IdentifierImpl {
  final ast.NamedType node;

  _NamedTypeIdentifierImpl({
    required super.id,
    required super.name,
    required this.node,
  });

  @override
  Element? get element => node.element;
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}
