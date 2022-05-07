// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

class ClassDeclarationImpl extends macro.ClassDeclarationImpl {
  late final ClassElement element;

  ClassDeclarationImpl._({
    required int id,
    required macro.IdentifierImpl identifier,
    required List<macro.TypeParameterDeclarationImpl> typeParameters,
    required List<macro.TypeAnnotationImpl> interfaces,
    required bool isAbstract,
    required bool isExternal,
    required List<macro.TypeAnnotationImpl> mixins,
    required macro.TypeAnnotationImpl? superclass,
  }) : super(
          id: id,
          identifier: identifier,
          typeParameters: typeParameters,
          interfaces: interfaces,
          isAbstract: isAbstract,
          isExternal: isExternal,
          mixins: mixins,
          superclass: superclass,
        );
}

class DeclarationBuilder {
  final DeclarationBuilderFromNode fromNode = DeclarationBuilderFromNode();

  final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement();

  /// Associate declarations that were previously created for nodes with the
  /// corresponding elements. So, we can access them uniformly via interfaces,
  /// mixins, etc.
  void transferToElements() {
    for (final entry in fromNode._identifierMap.entries) {
      final element = entry.key.staticElement;
      if (element != null) {
        final declaration = entry.value;
        declaration.element = element;
        fromElement._identifierMap[element] = declaration;
      }
    }

    for (final entry in fromNode._classMap.entries) {
      final element = entry.key.declaredElement as ClassElement;
      final declaration = entry.value;
      declaration.element = element;
      fromElement._classMap[element] = declaration;
    }
  }
}

class DeclarationBuilderFromElement {
  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();

  final Map<ClassElement, ClassDeclarationImpl> _classMap = Map.identity();

  final Map<FieldElement, FieldDeclarationImpl> _fieldMap = Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterDeclarationImpl>
      _typeParameterMap = Map.identity();

  macro.ClassDeclarationImpl classElement(ClassElement element) {
    return _classMap[element] ??= _classElement(element);
  }

  macro.FieldDeclarationImpl fieldElement(FieldElement element) {
    return _fieldMap[element] ??= _fieldElement(element);
  }

  macro.IdentifierImpl identifier(Element element) {
    return _identifierMap[element] ??= IdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: element.name!,
    )..element = element;
  }

  macro.TypeParameterDeclarationImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  ClassDeclarationImpl _classElement(ClassElement element) {
    assert(!_classMap.containsKey(element));
    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      typeParameters: element.typeParameters.map(_typeParameter).toList(),
      interfaces: element.interfaces.map(_dartType).toList(),
      isAbstract: element.isAbstract,
      isExternal: false,
      mixins: element.mixins.map(_dartType).toList(),
      superclass: element.supertype.mapOrNull(_dartType),
    )..element = element;
  }

  macro.TypeAnnotationImpl _dartType(DartType type) {
    if (type is InterfaceType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        identifier: identifier(type.element),
        typeArguments: type.typeArguments.map(_dartType).toList(),
      );
    } else if (type is TypeParameterType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
        identifier: identifier(type.element),
        typeArguments: const [],
      );
    } else {
      // TODO(scheglov) other types
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  FieldDeclarationImpl _fieldElement(FieldElement element) {
    assert(!_fieldMap.containsKey(element));
    final enclosingClass = element.enclosingElement as ClassElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      isExternal: element.isExternal,
      isFinal: element.isFinal,
      isLate: element.isLate,
      type: _dartType(element.type),
      definingClass: identifier(enclosingClass),
      isStatic: element.isStatic,
    );
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    TypeParameterElement element,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      bound: element.bound.mapOrNull(_dartType),
    );
  }
}

class DeclarationBuilderFromNode {
  final Map<ast.SimpleIdentifier, IdentifierImpl> _identifierMap =
      Map.identity();

  final Map<ast.ClassDeclaration, ClassDeclarationImpl> _classMap =
      Map.identity();

  macro.ClassDeclarationImpl classDeclaration(
    ast.ClassDeclaration node,
  ) {
    return _classMap[node] ??= _classDeclaration(node);
  }

  ClassDeclarationImpl _classDeclaration(
    ast.ClassDeclaration node,
  ) {
    assert(!_classMap.containsKey(node));
    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _identifier(node.name),
      typeParameters: _typeParameters(node.typeParameters),
      interfaces: _typeAnnotations(node.implementsClause?.interfaces),
      isAbstract: node.abstractKeyword != null,
      isExternal: false,
      mixins: _typeAnnotations(node.withClause?.mixinTypes),
      superclass: node.extendsClause?.superclass.mapOrNull(
        _typeAnnotation,
      ),
    );
  }

  macro.FunctionTypeParameterImpl _formalParameter(
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
      name: node.identifier?.name,
      type: typeAnnotation,
    );
  }

  macro.IdentifierImpl _identifier(ast.Identifier node) {
    final ast.SimpleIdentifier simpleIdentifier;
    if (node is ast.SimpleIdentifier) {
      simpleIdentifier = node;
    } else {
      simpleIdentifier = (node as ast.PrefixedIdentifier).identifier;
    }
    return _identifierMap[simpleIdentifier] ??= IdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: simpleIdentifier.name,
    );
  }

  macro.TypeAnnotationImpl _typeAnnotation(ast.TypeAnnotation? node) {
    if (node == null) {
      return macro.OmittedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
      );
    } else if (node is ast.GenericFunctionType) {
      return macro.FunctionTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        isNullable: node.question != null,
        namedParameters: node.parameters.parameters
            .where((e) => e.isNamed)
            .map(_formalParameter)
            .toList(),
        positionalParameters: node.parameters.parameters
            .where((e) => e.isPositional)
            .map(_formalParameter)
            .toList(),
        returnType: _typeAnnotation(node.returnType),
        typeParameters: _typeParameters(node.typeParameters),
      );
    } else if (node is ast.NamedType) {
      return macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: _identifier(node.name),
        isNullable: node.question != null,
        typeArguments: _typeAnnotations(node.typeArguments?.arguments),
      );
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }
  }

  List<macro.TypeAnnotationImpl> _typeAnnotations(
    List<ast.TypeAnnotation>? elements,
  ) {
    if (elements != null) {
      return elements.map(_typeAnnotation).toList();
    } else {
      return const [];
    }
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _identifier(node.name),
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
    required int id,
    required macro.IdentifierImpl identifier,
    required bool isExternal,
    required bool isFinal,
    required bool isLate,
    required macro.TypeAnnotationImpl type,
    required macro.IdentifierImpl definingClass,
    required bool isStatic,
  }) : super(
          id: id,
          identifier: identifier,
          isExternal: isExternal,
          isFinal: isFinal,
          isLate: isLate,
          type: type,
          definingClass: definingClass,
          isStatic: isStatic,
        );
}

class IdentifierImpl extends macro.IdentifierImpl {
  late final Element? element;

  IdentifierImpl({required int id, required String name})
      : super(id: id, name: name);
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}
