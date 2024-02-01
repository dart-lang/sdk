// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor.dart' as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/exception_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart'
    as macro;
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart'
    as macro;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:collection/collection.dart';

class ClassDeclarationImpl extends macro.ClassDeclarationImpl
    implements HasElement {
  @override
  final ClassElementImpl element;

  ClassDeclarationImpl._({
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

class ConstructorDeclarationImpl extends macro.ConstructorDeclarationImpl
    implements HasElement {
  @override
  final ConstructorElementImpl element;

  ConstructorDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasBody,
    required super.hasExternal,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required super.definingType,
    required super.isFactory,
    required this.element,
  });
}

class DeclarationBuilder {
  final ast.AstNode? Function(Element?) nodeOfElement;

  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();

  late final DeclarationBuilderFromNode fromNode =
      DeclarationBuilderFromNode(this);

  late final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement(this);

  DeclarationBuilder({
    required this.nodeOfElement,
  });

  macro.MacroTarget buildTarget(ast.AstNode node) {
    switch (node) {
      case ast.ClassDeclarationImpl():
        return fromNode.classDeclaration(node);
      case ast.ClassTypeAliasImpl():
        return fromNode.classTypeAlias(node);
      case ast.ConstructorDeclarationImpl():
        return fromNode.constructorDeclaration(node);
      case ast.EnumDeclarationImpl():
        return fromNode.enumDeclaration(node);
      case ast.EnumConstantDeclarationImpl():
        return fromNode.enumConstantDeclaration(node);
      case ast.ExtensionDeclarationImpl():
        return fromNode.extensionDeclaration(node);
      case ast.ExtensionTypeDeclarationImpl():
        return fromNode.extensionTypeDeclaration(node);
      case ast.FunctionDeclarationImpl():
        return fromNode.functionDeclaration(node);
      case ast.LibraryDirectiveImpl():
        return fromNode.libraryDirective(node);
      case ast.MethodDeclarationImpl():
        return fromNode.methodDeclaration(node);
      case ast.MixinDeclarationImpl():
        return fromNode.mixinDeclaration(node);
      case ast.VariableDeclaration():
        return fromNode.variableDeclaration(node);
    }
    // TODO(scheglov): incomplete
    throw UnimplementedError('${node.runtimeType}');
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOf(macro.Identifier identifier) {
    if (identifier is! IdentifierImpl) {
      throw macro.MacroImplementationExceptionImpl('Not analyzer identifier.');
    }

    final element = identifier.element;
    if (element == null) {
      throw macro.MacroImplementationExceptionImpl(
          'Identifier without element.');
    }

    return declarationOfElement(element);
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOfElement(Element element) {
    final node = nodeOfElement(element);
    if (node != null) {
      return fromNode.declarationOf(node);
    } else {
      return fromElement.declarationOf(element);
    }
  }

  macro.TypeAnnotation inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    final type = resolveType(omittedType.code);
    return fromElement._dartType(type);
  }

  macro.ResolvedIdentifier resolveIdentifier(macro.Identifier identifier) {
    if (identifier is _VoidIdentifierImpl) {
      return macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.topLevelMember,
        name: 'void',
        uri: null,
        staticScope: null,
      );
    }

    identifier as IdentifierImpl;
    final element = identifier.element;
    switch (element) {
      case ConstructorElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.staticInstanceMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: element.enclosingElement.name,
        );
      case DynamicElementImpl():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: 'dynamic',
          uri: Uri.parse('dart:core'),
          staticScope: null,
        );
      case ExtensionElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name ?? '',
          uri: element.library.source.uri,
          staticScope: null,
        );
      case FieldElement():
        if (element.isStatic) {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.staticInstanceMember,
            name: element.name,
            uri: element.library.source.uri,
            staticScope: element.enclosingElement.name,
          );
        } else {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.instanceMember,
            name: element.name,
            uri: null,
            staticScope: null,
          );
        }
      case FunctionElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: null,
        );
      case InterfaceElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: null,
        );
      case MethodElement():
        if (element.isStatic) {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.staticInstanceMember,
            name: element.name,
            uri: element.library.source.uri,
            staticScope: element.enclosingElement.name,
          );
        } else {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.instanceMember,
            name: element.name,
            uri: null,
            staticScope: null,
          );
        }
      case ParameterElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.local,
          name: element.name,
          uri: null,
          staticScope: null,
        );
      case PropertyAccessorElement():
        if (element.enclosingElement is CompilationUnitElement) {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.topLevelMember,
            name: element.name,
            uri: element.library.source.uri,
            staticScope: null,
          );
        } else if (element.isStatic) {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.staticInstanceMember,
            name: element.name,
            uri: element.library.source.uri,
            staticScope: element.enclosingElement.name,
          );
        } else {
          return macro.ResolvedIdentifier(
            kind: macro.IdentifierKind.instanceMember,
            name: element.name,
            uri: null,
            staticScope: null,
          );
        }
      case TopLevelVariableElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: null,
        );
      case TypeAliasElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.topLevelMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: null,
        );
      case TypeParameterElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.local,
          name: element.name,
          uri: null,
          staticScope: null,
        );
      default:
        throw UnimplementedError('${element.runtimeType}');
    }
  }

  DartType resolveType(macro.TypeAnnotationCode typeCode) {
    switch (typeCode) {
      case macro.NullableTypeAnnotationCode():
        final type = resolveType(typeCode.underlyingType);
        type as TypeImpl;
        return type.withNullability(NullabilitySuffix.question);
      case macro.FunctionTypeAnnotationCode():
        return _resolveTypeCodeFunction(typeCode);
      case macro.NamedTypeAnnotationCode():
        return _resolveTypeCodeNamed(typeCode);
      case macro.OmittedTypeAnnotationCode():
        return _resolveTypeCodeOmitted(typeCode);
      case macro.RawTypeAnnotationCode():
        throw macro.MacroImplementationExceptionImpl('Not supported');
      case macro.RecordTypeAnnotationCode():
        return _resolveTypeCodeRecord(typeCode);
    }
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(macro.Identifier identifier) {
    if (identifier is! IdentifierImpl) {
      throw macro.MacroImplementationExceptionImpl('Not analyzer identifier.');
    }

    final element = identifier.element;
    if (element == null) {
      throw macro.MacroImplementationExceptionImpl(
          'Identifier without element.');
    }

    final node = nodeOfElement(element);
    if (node != null) {
      return fromNode.typeDeclarationOf(node);
    } else {
      return fromElement.typeDeclarationOf(element);
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return element.withAugmentations
        .expand((current) => current.metadata)
        .map(_buildMetadataElement)
        .nonNulls
        .toList();
  }

  macro.MetadataAnnotationImpl? _buildMetadataElement(
    ElementAnnotation annotation,
  ) {
    annotation as ElementAnnotationImpl;
    final node = annotation.annotationAst;

    final importPrefixNames = annotation.library.libraryImports
        .map((e) => e.prefix?.element.name)
        .nonNulls
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

    final identifierMacro = IdentifierImplFromNode(
      id: macro.RemoteInstance.uniqueId,
      name: identifierName.name,
      getElement: () => identifierName.staticElement,
    );

    final argumentList = node.arguments;
    if (argumentList != null) {
      final arguments = argumentList.arguments;
      return macro.ConstructorMetadataAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        constructor: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: constructorName?.name ?? '',
          getElement: () => node.element,
        ),
        type: identifierMacro,
        positionalArguments: arguments
            .whereNotType<ast.NamedExpression>()
            .map((e) => _expressionCode(e))
            .toList(),
        namedArguments: arguments.whereType<ast.NamedExpression>().map((e) {
          return MapEntry(
            e.name.label.name,
            _expressionCode(e.expression),
          );
        }).mapFromEntries,
      );
    } else {
      return macro.IdentifierMetadataAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: identifierMacro,
      );
    }
  }

  FunctionTypeImpl _resolveTypeCodeFunction(
    macro.FunctionTypeAnnotationCode typeCode,
  ) {
    ParameterElementImpl buildFormalParameter(
      macro.ParameterCode e,
      ParameterKind Function(macro.ParameterCode) getKind,
    ) {
      final element = ParameterElementImpl(
        name: e.name,
        nameOffset: -1,
        parameterKind: getKind(e),
      );
      element.type = switch (e.type) {
        final type? => resolveType(type),
        _ => DynamicTypeImpl.instance,
      };
      return element;
    }

    return FunctionTypeImpl(
      typeFormals: typeCode.typeParameters
          .map((e) => TypeParameterElementImpl(e.name, -1))
          .toList(),
      parameters: [
        ...typeCode.positionalParameters.map((e) {
          return buildFormalParameter(e, (e) {
            return ParameterKind.REQUIRED;
          });
        }),
        ...typeCode.optionalPositionalParameters.map((e) {
          return buildFormalParameter(e, (e) {
            return ParameterKind.POSITIONAL;
          });
        }),
        ...typeCode.namedParameters.map((e) {
          return buildFormalParameter(e, (e) {
            return e.keywords.contains('required')
                ? ParameterKind.NAMED_REQUIRED
                : ParameterKind.NAMED;
          });
        }),
      ],
      returnType: switch (typeCode.returnType) {
        final returnType? => resolveType(returnType),
        _ => DynamicTypeImpl.instance,
      },
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _resolveTypeCodeNamed(macro.NamedTypeAnnotationCode typeCode) {
    final identifier = typeCode.name as IdentifierImpl;
    if (identifier is _VoidIdentifierImpl) {
      return VoidTypeImpl.instance;
    }

    final element = identifier.element;
    switch (element) {
      case DynamicElementImpl():
        return DynamicTypeImpl.instance;
      case InterfaceElementImpl():
        return element.instantiate(
          typeArguments: typeCode.typeArguments.map(resolveType).toList(),
          nullabilitySuffix: NullabilitySuffix.none,
        );
      case TypeParameterElementImpl():
        return element.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      default:
        throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  DartType _resolveTypeCodeOmitted(macro.OmittedTypeAnnotationCode typeCode) {
    final omittedType = typeCode.typeAnnotation;
    switch (omittedType) {
      case _OmittedTypeAnnotationDynamic():
        return DynamicTypeImpl.instance;
      case _OmittedTypeAnnotationFunctionReturnType():
        return omittedType.element.returnType;
      case _OmittedTypeAnnotationVariable():
        return omittedType.element.type;
      default:
        throw UnimplementedError('${omittedType.runtimeType}');
    }
  }

  RecordTypeImpl _resolveTypeCodeRecord(
    macro.RecordTypeAnnotationCode typeCode,
  ) {
    return RecordTypeImpl(
      positionalFields: typeCode.positionalFields.map((e) {
        return RecordTypePositionalFieldImpl(
          type: resolveType(e.type),
        );
      }).toList(),
      namedFields: typeCode.namedFields.map((e) {
        return RecordTypeNamedFieldImpl(
          name: e.name!,
          type: resolveType(e.type),
        );
      }).toList(),
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  static macro.ExpressionCode _expressionCode(ast.Expression node) {
    return macro.ExpressionCode.fromString('$node');
  }
}

class DeclarationBuilderFromElement {
  final DeclarationBuilder declarationBuilder;

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  final Map<ClassElement, ClassDeclarationImpl> _classMap = Map.identity();

  final Map<EnumElement, EnumDeclarationImpl> _enumMap = Map.identity();

  final Map<FieldElement, EnumValueDeclarationImpl> _enumConstantMap =
      Map.identity();

  final Map<ExtensionElement, ExtensionDeclarationImpl> _extensionMap =
      Map.identity();

  final Map<ExtensionTypeElement, ExtensionTypeDeclarationImpl>
      _extensionTypeMap = Map.identity();

  final Map<ExecutableElement, FunctionDeclarationImpl> _functionMap =
      Map.identity();

  final Map<MixinElement, MixinDeclarationImpl> _mixinMap = Map.identity();

  final Map<ConstructorElement, ConstructorDeclarationImpl> _constructorMap =
      Map.identity();

  final Map<FieldElement, FieldDeclarationImpl> _fieldMap = Map.identity();

  final Map<ExecutableElement, MethodDeclarationImpl> _methodMap =
      Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterDeclarationImpl>
      _typeParameterMap = Map.identity();

  final Map<TopLevelVariableElement, VariableDeclarationImpl> _variableMap =
      Map.identity();

  DeclarationBuilderFromElement(this.declarationBuilder);

  macro.ClassDeclarationImpl classElement(
    ClassElementImpl element,
  ) {
    return _classMap[element] ??= _classElement(element);
  }

  ConstructorDeclarationImpl constructorElement(
    ConstructorElementImpl element,
  ) {
    return _constructorMap[element] ??= _constructorElement(element);
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOf(Element element) {
    switch (element) {
      case ConstructorElementImpl():
        return constructorElement(element);
      case FieldElementImpl():
        return fieldElement(element);
      case FunctionElementImpl():
        return functionElement(element);
      case MethodElementImpl():
        return methodElement(element);
      case PropertyAccessorElementImpl():
        if (element.enclosingElement is CompilationUnitElement) {
          return functionElement(element);
        } else {
          return methodElement(element);
        }
      case TopLevelVariableElementImpl():
        return topLevelVariableElement(element);
      default:
        // TODO(scheglov): other elements
        return typeDeclarationOf(element);
    }
  }

  EnumDeclarationImpl enumElement(
    EnumElementImpl element,
  ) {
    return _enumMap[element] ??= _enumElement(element);
  }

  ExtensionDeclarationImpl extensionElement(
    ExtensionElementImpl element,
  ) {
    return _extensionMap[element] ??= _extensionElement(element);
  }

  ExtensionTypeDeclarationImpl extensionTypeElement(
    ExtensionTypeElementImpl element,
  ) {
    return _extensionTypeMap[element] ??= _extensionTypeElement(element);
  }

  macro.DeclarationImpl fieldElement(FieldElementImpl element) {
    if (element.isEnumConstant) {
      return _enumConstantMap[element] ??= _enumConstantElement(element);
    }

    return _fieldMap[element] ??= _fieldElement(element);
  }

  FunctionDeclarationImpl functionElement(ExecutableElementImpl element) {
    return _functionMap[element] ??= _functionElement(element);
  }

  macro.IdentifierImpl identifier(Element element) {
    final name = switch (element) {
      PropertyAccessorElement(isSetter: true) => element.displayName,
      _ => element.name!,
    };

    final map = declarationBuilder._identifierMap;
    return map[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.LibraryImpl library(Element element) {
    final libraryElement = element.library as LibraryElementImpl;
    var macroLibrary = _libraryMap[libraryElement];
    if (macroLibrary == null) {
      final version = libraryElement.languageVersion.effective;
      macroLibrary = LibraryImplFromElement(
        id: macro.RemoteInstance.uniqueId,
        languageVersion: macro.LanguageVersionImpl(
          version.major,
          version.minor,
        ),
        metadata: _buildMetadata(element),
        uri: libraryElement.source.uri,
        element: libraryElement,
      );
      _libraryMap[libraryElement] = macroLibrary;
    }
    return macroLibrary;
  }

  MethodDeclarationImpl methodElement(ExecutableElementImpl element) {
    return _methodMap[element] ??= _methodElement(element);
  }

  macro.MixinDeclarationImpl mixinElement(
    MixinElementImpl element,
  ) {
    return _mixinMap[element] ??= _mixinElement(element);
  }

  macro.VariableDeclarationImpl topLevelVariableElement(
    TopLevelVariableElementImpl element,
  ) {
    return _variableMap[element] ??= _topLevelVariableElement(element);
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(Element element) {
    switch (element) {
      case ClassElementImpl():
        return classElement(element);
      case EnumElementImpl():
        return enumElement(element);
      case ExtensionElementImpl():
        return extensionElement(element);
      case ExtensionTypeElementImpl():
        return extensionTypeElement(element);
      case MixinElementImpl():
        return mixinElement(element);
      default:
        // TODO(scheglov): other elements
        throw macro.MacroImplementationExceptionImpl(
            'element: (${element.runtimeType}) $element');
    }
  }

  macro.TypeParameterDeclarationImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return declarationBuilder._buildMetadata(element);
  }

  ClassDeclarationImpl _classElement(
    ClassElementImpl element,
  ) {
    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(element.typeParameters),
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

  ConstructorDeclarationImpl _constructorElement(
    ConstructorElementImpl element,
  ) {
    final enclosing = element.enclosingInstanceElement;
    return ConstructorDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isFactory: element.isFactory,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: _typeParameters(element.typeParameters),
      definingType: identifier(enclosing),
    );
  }

  macro.TypeAnnotationImpl _dartType(DartType type) {
    switch (type) {
      case DynamicType():
        return macro.NamedTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: false,
          identifier: identifier(DynamicElementImpl.instance),
          typeArguments: const [],
        );
      case FunctionType():
        return macro.FunctionTypeAnnotationImpl(
          id: macro.RemoteInstance.uniqueId,
          isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
          namedParameters: type.parameters
              .where((e) => e.isNamed)
              .map(_functionTypeFormalParameter)
              .toList(),
          positionalParameters: type.parameters
              .where((e) => e.isPositional)
              .map(_functionTypeFormalParameter)
              .toList(),
          returnType: _dartType(type.returnType),
          typeParameters: _typeParameters(type.typeFormals),
        );
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
          identifier: _VoidIdentifierImpl(),
          isNullable: false,
          typeArguments: const [],
        );
      default:
        // TODO(scheglov): implement other types
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  EnumValueDeclarationImpl _enumConstantElement(
    FieldElementImpl element,
  ) {
    final enclosing = element.enclosingElement as EnumElementImpl;
    return EnumValueDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      definingEnum: identifier(enclosing),
      // TODO(scheglov): restore, when added
      // type: _typeAnnotationVariable(variableList.type, element),
      element: element,
    );
  }

  EnumDeclarationImpl _enumElement(
    EnumElementImpl element,
  ) {
    return EnumDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(element.typeParameters),
      interfaces: element.interfaces.map(_interfaceType).toList(),
      mixins: element.mixins.map(_interfaceType).toList(),
      element: element,
    );
  }

  ExtensionDeclarationImpl _extensionElement(
    ExtensionElementImpl element,
  ) {
    return ExtensionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(element.typeParameters),
      onType: _dartType(element.extendedType),
      element: element,
    );
  }

  ExtensionTypeDeclarationImpl _extensionTypeElement(
    ExtensionTypeElementImpl element,
  ) {
    return ExtensionTypeDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(element.typeParameters),
      representationType: _dartType(element.representation.type),
      element: element,
    );
  }

  FieldDeclarationImpl _fieldElement(FieldElementImpl element) {
    final enclosing = element.enclosingInstanceElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: element.isAbstract,
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasLate: element.isLate,
      type: _dartType(element.type),
      definingType: identifier(enclosing),
      isStatic: element.isStatic,
      element: element,
    );
  }

  macro.ParameterDeclarationImpl _formalParameter(ParameterElement element) {
    return macro.ParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      isNamed: element.isNamed,
      isRequired: element.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      type: _dartType(element.type),
    );
  }

  FunctionDeclarationImpl _functionElement(ExecutableElementImpl element) {
    return FunctionDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isGetter: element is PropertyAccessorElementImpl && element.isGetter,
      isOperator: element.isOperator,
      isSetter: element is PropertyAccessorElementImpl && element.isSetter,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: _typeParameters(element.typeParameters),
    );
  }

  macro.FunctionTypeParameterImpl _functionTypeFormalParameter(
    ParameterElement element,
  ) {
    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: element.isNamed,
      isRequired: element.isRequired,
      metadata: _buildMetadata(element),
      name: element.name,
      type: _dartType(element.type),
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

  MethodDeclarationImpl _methodElement(ExecutableElementImpl element) {
    final enclosing = element.enclosingInstanceElement;
    return MethodDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isGetter: element is PropertyAccessorElementImpl && element.isGetter,
      isOperator: element.isOperator,
      isSetter: element is PropertyAccessorElementImpl && element.isSetter,
      isStatic: element.isStatic,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: _typeParameters(element.typeParameters),
      definingType: identifier(enclosing),
    );
  }

  MixinDeclarationImpl _mixinElement(
    MixinElementImpl element,
  ) {
    return MixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(element.typeParameters),
      hasBase: element.isBase,
      interfaces: element.interfaces.map(_interfaceType).toList(),
      superclassConstraints:
          element.superclassConstraints.map(_interfaceType).toList(),
      element: element,
    );
  }

  List<macro.ParameterDeclarationImpl> _namedFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isNamed)
        .map(_formalParameter)
        .toList();
  }

  List<macro.ParameterDeclarationImpl> _positionalFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isPositional)
        .map(_formalParameter)
        .toList();
  }

  VariableDeclarationImpl _topLevelVariableElement(
    TopLevelVariableElementImpl element,
  ) {
    return VariableDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasLate: element.isLate,
      type: _dartType(element.type),
      element: element,
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

  List<macro.TypeParameterDeclarationImpl> _typeParameters(
    List<TypeParameterElement> elements,
  ) {
    return elements.map(typeParameter).toList();
  }
}

class DeclarationBuilderFromNode {
  final DeclarationBuilder declarationBuilder;

  final Map<ast.NamedType, IdentifierImpl> _namedTypeMap = Map.identity();

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  DeclarationBuilderFromNode(this.declarationBuilder);

  ClassDeclarationImpl classDeclaration(
    ast.ClassDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

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
      if (nextNode is! ast.ClassDeclarationImpl) {
        break;
      }
      current = nextNode;
    }

    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
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

  ClassDeclarationImpl classTypeAlias(
    ast.ClassTypeAliasImpl node,
  ) {
    final element = node.declaredElement!;

    final interfaceNodes = <ast.NamedType>[];
    final mixinNodes = <ast.NamedType>[];
    for (var current = node;;) {
      if (current.implementsClause case final clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      mixinNodes.addAll(current.withClause.mixinTypes);
      final nextElement = current.declaredElement?.augmentation;
      final nextNode = declarationBuilder.nodeOfElement(nextElement);
      if (nextNode is! ast.ClassTypeAliasImpl) {
        break;
      }
      current = nextNode;
    }

    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
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
      superclass: node.superclass.mapOrNull(_namedType),
      element: element,
    );
  }

  macro.ConstructorDeclarationImpl constructorDeclaration(
    ast.ConstructorDeclarationImpl node,
  ) {
    final definingType = _definingType(node);
    final element = node.declaredElement!;

    return ConstructorDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isFactory: node.factoryKeyword != null,
      namedParameters: _namedFormalParameters(node.parameters),
      positionalParameters: _positionalFormalParameters(node.parameters),
      returnType: macro.NamedTypeAnnotationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: definingType,
        typeArguments: const [],
        isNullable: false,
      ),
      typeParameters: const [],
    );
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOf(ast.AstNode node) {
    switch (node) {
      case ast.ConstructorDeclarationImpl():
        return constructorDeclaration(node);
      case ast.FunctionDeclarationImpl():
        return functionDeclaration(node);
      case ast.MethodDeclarationImpl():
        return methodDeclaration(node);
      case ast.RepresentationDeclaration():
        return representationDeclaration(node);
      case ast.VariableDeclaration():
        return variableDeclaration(node);
      default:
        // TODO(scheglov): other nodes
        return typeDeclarationOf(node);
    }
  }

  macro.EnumValueDeclarationImpl enumConstantDeclaration(
    ast.EnumConstantDeclarationImpl node,
  ) {
    final element = node.declaredElement!;
    return _enumConstantDeclaration(element);
  }

  EnumDeclarationImpl enumDeclaration(
    ast.EnumDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    // TODO(scheglov): this is duplicate
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
      if (nextNode is! ast.EnumDeclarationImpl) {
        break;
      }
      current = nextNode;
    }

    return EnumDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      interfaces: _namedTypes(interfaceNodes),
      mixins: _namedTypes(mixinNodes),
      element: element,
    );
  }

  ExtensionDeclarationImpl extensionDeclaration(
    ast.ExtensionDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    return ExtensionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      onType: _typeAnnotation(node.extendedType),
      element: element,
    );
  }

  ExtensionTypeDeclarationImpl extensionTypeDeclaration(
    ast.ExtensionTypeDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    return ExtensionTypeDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name.lexeme, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      representationType: _typeAnnotation(node.representation.fieldType),
      element: element,
    );
  }

  macro.FunctionDeclarationImpl functionDeclaration(
    ast.FunctionDeclarationImpl node,
  ) {
    final element = node.declaredElement!;
    final function = node.functionExpression;

    return FunctionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: function.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isOperator: false,
      isSetter: node.isSetter,
      namedParameters: _namedFormalParameters(function.parameters),
      positionalParameters: _positionalFormalParameters(function.parameters),
      returnType: _typeAnnotationFunctionReturnType(node),
      typeParameters: _typeParameters(function.typeParameters),
    );
  }

  macro.LibraryImpl library(Element element) {
    final libraryElement = element.library as LibraryElementImpl;

    if (_libraryMap[libraryElement] case final result?) {
      return result;
    }

    final version = libraryElement.languageVersion.effective;
    final uri = libraryElement.source.uri;

    return _libraryMap[libraryElement] = LibraryImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      languageVersion: macro.LanguageVersionImpl(
        version.major,
        version.minor,
      ),
      metadata: _buildMetadata(element),
      uri: uri,
      element: libraryElement,
    );
  }

  macro.Library libraryDirective(
    ast.LibraryDirectiveImpl node,
  ) {
    final element = node.element as LibraryElementImpl;
    return library(element);
  }

  macro.MethodDeclarationImpl methodDeclaration(
    ast.MethodDeclarationImpl node,
  ) {
    return _methodDeclaration(node);
  }

  MixinDeclarationImpl mixinDeclaration(
    ast.MixinDeclarationImpl node,
  ) {
    final element = node.declaredElement!;

    // TODO(scheglov): this is duplicate (partial)
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
      if (nextNode is! ast.MixinDeclarationImpl) {
        break;
      }
      current = nextNode;
    }

    return MixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameters(node.typeParameters),
      hasBase: node.baseKeyword != null,
      interfaces: _namedTypes(interfaceNodes),
      superclassConstraints: _namedTypes(onNodes),
      element: element,
    );
  }

  macro.FieldDeclarationImpl representationDeclaration(
    ast.RepresentationDeclaration node,
  ) {
    final element = node.fieldElement as FieldElementImpl;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.fieldName, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: false,
      hasExternal: false,
      hasFinal: element.isFinal,
      hasLate: element.isLate,
      type: _typeAnnotationVariable(node.fieldType, element),
      definingType: _definingType(node),
      isStatic: element.isStatic,
      element: element,
    );
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(ast.AstNode node) {
    switch (node) {
      case ast.ClassDeclarationImpl():
        return classDeclaration(node);
      case ast.ClassTypeAliasImpl():
        return classTypeAlias(node);
      case ast.EnumDeclarationImpl():
        return enumDeclaration(node);
      case ast.ExtensionDeclarationImpl():
        return extensionDeclaration(node);
      case ast.ExtensionTypeDeclarationImpl():
        return extensionTypeDeclaration(node);
      case ast.MixinDeclarationImpl():
        return mixinDeclaration(node);
      default:
        // TODO(scheglov): other nodes
        throw macro.MacroImplementationExceptionImpl(
            'node: (${node.runtimeType}) $node');
    }
  }

  macro.DeclarationImpl variableDeclaration(
    ast.VariableDeclaration node,
  ) {
    final variableList = node.parent as ast.VariableDeclarationList;
    final variablesDeclaration = variableList.parent;

    final element = node.declaredElement;
    if (element is FieldElementImpl && element.isEnumConstant) {
      return _enumConstantDeclaration(element);
    }

    switch (variablesDeclaration) {
      case ast.FieldDeclarationImpl():
        final element = node.declaredElement as FieldElementImpl;
        return FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _declaredIdentifier(node.name, element),
          library: library(element),
          metadata: _buildMetadata(element),
          hasAbstract: variablesDeclaration.abstractKeyword != null,
          hasExternal: variablesDeclaration.externalKeyword != null,
          hasFinal: element.isFinal,
          hasLate: element.isLate,
          type: _typeAnnotationVariable(variableList.type, element),
          definingType: _definingType(variablesDeclaration),
          isStatic: element.isStatic,
          element: element,
        );
      case ast.TopLevelVariableDeclarationImpl():
        final element = node.declaredElement as TopLevelVariableElementImpl;
        return VariableDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _declaredIdentifier(node.name, element),
          library: library(element),
          metadata: _buildMetadata(element),
          hasExternal: element.isExternal,
          hasFinal: element.isFinal,
          hasLate: element.isLate,
          type: _typeAnnotationVariable(variableList.type, element),
          element: element,
        );
      default:
        throw UnimplementedError('${variablesDeclaration.runtimeType}');
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return declarationBuilder._buildMetadata(element);
  }

  macro.IdentifierImpl _declaredIdentifier(Token name, Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name.lexeme,
      element: element,
    );
  }

  macro.IdentifierImpl _declaredIdentifier2(String name, Element element) {
    final map = declarationBuilder._identifierMap;
    return map[element] ??= _DeclaredIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: name,
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
      case ast.EnumDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.ExtensionDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier2(parentNode.name?.lexeme ?? '', typeElement);
      case ast.ExtensionTypeDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.MixinDeclaration():
        final parentElement = parentNode.declaredElement!;
        final typeElement = parentElement.augmentationTarget ?? parentElement;
        return _declaredIdentifier(parentNode.name, typeElement);
      default:
        // TODO(scheglov): other parents
        throw UnimplementedError('(${parentNode.runtimeType}) $parentNode');
    }
  }

  macro.EnumValueDeclarationImpl _enumConstantDeclaration(
    FieldElementImpl element,
  ) {
    final enclosing = element.enclosingElement as EnumElementImpl;
    return EnumValueDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(element.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      definingEnum: _declaredIdentifier2(enclosing.name, enclosing),
      // TODO(scheglov): restore, when added
      // type: _typeAnnotationVariable(variableList.type, element),
      element: element,
    );
  }

  macro.ParameterDeclarationImpl _formalParameter(ast.FormalParameter node) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final element = node.declaredElement!;

    final macro.TypeAnnotationImpl typeAnnotation;
    switch (node) {
      case ast.FieldFormalParameter():
        typeAnnotation = _typeAnnotationVariable(node.type, element);
      case ast.SimpleFormalParameter():
        typeAnnotation = _typeAnnotationVariable(node.type, element);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.ParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name!, element),
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      type: typeAnnotation,
    );
  }

  macro.FunctionTypeParameterImpl _functionTypeFormalParameter(
    ast.FormalParameter node,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    final element = node.declaredElement!;

    final macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotationOrDynamic(node.type);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FunctionTypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      metadata: _buildMetadata(element),
      name: node.name?.lexeme,
      type: typeAnnotation,
    );
  }

  MethodDeclarationImpl _methodDeclaration(
    ast.MethodDeclarationImpl node,
  ) {
    final definingType = _definingType(node);
    final element = node.declaredElement!;

    return MethodDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isGetter: node.isGetter,
      isOperator: node.isOperator,
      isSetter: node.isSetter,
      isStatic: node.isStatic,
      namedParameters: _namedFormalParameters(node.parameters),
      positionalParameters: _positionalFormalParameters(node.parameters),
      returnType: _typeAnnotationMethodReturnType(node),
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
    if (node.importPrefix == null && node.name2.lexeme == 'void') {
      return _namedTypeMap[node] ??= _VoidIdentifierImpl();
    }

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

  macro.TypeAnnotationImpl _typeAnnotation(ast.TypeAnnotation node) {
    node as ast.TypeAnnotationImpl;
    switch (node) {
      case ast.GenericFunctionTypeImpl():
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
          returnType: _typeAnnotationOrDynamic(node.returnType),
          typeParameters: _typeParameters(node.typeParameters),
        );
      case ast.NamedTypeImpl():
        return _namedType(node);
      case ast.RecordTypeAnnotationImpl():
        return _typeAnnotationRecord(node);
    }
  }

  macro.TypeAnnotationImpl _typeAnnotationFunctionReturnType(
    ast.FunctionDeclaration node,
  ) {
    final returnType = node.returnType;
    if (returnType == null) {
      final element = node.declaredElement!;
      return _OmittedTypeAnnotationFunctionReturnType(element);
    }
    return _typeAnnotation(returnType);
  }

  macro.TypeAnnotationImpl _typeAnnotationMethodReturnType(
    ast.MethodDeclaration node,
  ) {
    final returnType = node.returnType;
    if (returnType == null) {
      final element = node.declaredElement!;
      return _OmittedTypeAnnotationFunctionReturnType(element);
    }
    return _typeAnnotation(returnType);
  }

  macro.TypeAnnotationImpl _typeAnnotationOrDynamic(ast.TypeAnnotation? node) {
    if (node == null) {
      return _OmittedTypeAnnotationDynamic();
    }
    return _typeAnnotation(node);
  }

  macro.RecordTypeAnnotationImpl _typeAnnotationRecord(
    ast.RecordTypeAnnotation node,
  ) {
    final unitNode = node.thisOrAncestorOfType<ast.CompilationUnit>()!;
    final unitElement = unitNode.declaredElement!;
    final macroLibrary = library(unitElement);

    macro.RecordFieldDeclarationImpl buildField(
      ast.RecordTypeAnnotationField field,
    ) {
      final name = field.name?.lexeme ?? '';
      return macro.RecordFieldDeclarationImpl(
        id: macro.RemoteInstance.uniqueId,
        identifier: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: name,
          getElement: () => null,
        ),
        library: macroLibrary,
        metadata: const [],
        name: name,
        type: _typeAnnotationOrDynamic(field.type),
      );
    }

    return macro.RecordTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      positionalFields: node.positionalFields.map(buildField).toList(),
      namedFields: node.namedFields?.fields.map(buildField).toList() ?? [],
      isNullable: node.question != null,
    );
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

  macro.TypeAnnotationImpl _typeAnnotationVariable(
    ast.TypeAnnotation? type,
    VariableElement element,
  ) {
    if (type == null) {
      return _OmittedTypeAnnotationVariable(element);
    }
    return _typeAnnotation(type);
  }

  macro.TypeParameterDeclarationImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    final element = node.declaredElement!;
    return macro.TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
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

class EnumDeclarationImpl extends macro.EnumDeclarationImpl
    implements HasElement {
  @override
  final EnumElementImpl element;

  EnumDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.interfaces,
    required super.mixins,
    required this.element,
  });
}

class EnumValueDeclarationImpl extends macro.EnumValueDeclarationImpl
    implements HasElement {
  @override
  final FieldElementImpl element;

  EnumValueDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.definingEnum,
    // TODO(scheglov): restore, when added
    // required super.type,
    required this.element,
  });
}

class ExtensionDeclarationImpl extends macro.ExtensionDeclarationImpl
    implements HasElement {
  @override
  final ExtensionElementImpl element;

  ExtensionDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.onType,
    required this.element,
  });
}

class ExtensionTypeDeclarationImpl extends macro.ExtensionTypeDeclarationImpl
    implements HasElement {
  @override
  final ExtensionTypeElementImpl element;

  ExtensionTypeDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.representationType,
    required this.element,
  });
}

class FieldDeclarationImpl extends macro.FieldDeclarationImpl
    implements HasElement {
  @override
  final FieldElementImpl element;

  FieldDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasAbstract,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasLate,
    required super.type,
    required super.definingType,
    required super.isStatic,
    required this.element,
  });
}

class FunctionDeclarationImpl extends macro.FunctionDeclarationImpl
    implements HasElement {
  @override
  final ExecutableElementImpl element;

  FunctionDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasBody,
    required super.hasExternal,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required this.element,
  });
}

/// A macro declaration that has an [Element].
abstract interface class HasElement {
  ElementImpl get element;
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
  final LibraryElementImpl element;

  LibraryImplFromElement({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
    required this.element,
  });
}

class MethodDeclarationImpl extends macro.MethodDeclarationImpl
    implements HasElement {
  @override
  final ExecutableElementImpl element;

  MethodDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
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

class MixinDeclarationImpl extends macro.MixinDeclarationImpl
    implements HasElement {
  @override
  final MixinElementImpl element;

  MixinDeclarationImpl._({
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

class VariableDeclarationImpl extends macro.VariableDeclarationImpl
    implements HasElement {
  @override
  final VariableElementImpl element;

  VariableDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasLate,
    required super.type,
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

sealed class _OmittedTypeAnnotation extends macro.OmittedTypeAnnotationImpl {
  _OmittedTypeAnnotation()
      : super(
          id: macro.RemoteInstance.uniqueId,
        );
}

class _OmittedTypeAnnotationDynamic extends _OmittedTypeAnnotation {
  _OmittedTypeAnnotationDynamic();
}

class _OmittedTypeAnnotationFunctionReturnType extends _OmittedTypeAnnotation {
  final ExecutableElement element;

  _OmittedTypeAnnotationFunctionReturnType(this.element);
}

class _OmittedTypeAnnotationVariable extends _OmittedTypeAnnotation {
  final VariableElement element;

  _OmittedTypeAnnotationVariable(this.element);
}

class _VoidIdentifierImpl extends IdentifierImpl {
  _VoidIdentifierImpl()
      : super(
          id: macro.RemoteInstance.uniqueId,
          name: 'void',
        );

  @override
  Element? get element => null;
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    final self = this;
    return self != null ? mapper(self) : null;
  }
}

extension on Element {
  /// With the assumption that enclosing element is an [InstanceElement], and
  /// is not an invalid augmentation, return the declaration - the start of
  /// the augmentation chain.
  InstanceElement get enclosingInstanceElement {
    final enclosing = enclosingElement as InstanceElement;
    return enclosing.augmented!.declaration;
  }
}
