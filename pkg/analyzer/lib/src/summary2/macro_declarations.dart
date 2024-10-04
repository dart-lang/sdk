// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/macro_type_location.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:macros/macros.dart' as macro;
import 'package:macros/src/executor.dart' as macro;
import 'package:macros/src/executor/exception_impls.dart' as macro;
import 'package:macros/src/executor/introspection_impls.dart' as macro;
import 'package:macros/src/executor/remote_instance.dart' as macro;

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
    required super.isConst,
    required super.isFactory,
    required this.element,
  });
}

final class ConstructorMetadataAnnotationImpl extends macro
    .ConstructorMetadataAnnotationImpl implements MetadataAnnotationImpl {
  @override
  final ElementImpl element;

  @override
  final int annotationIndex;

  ConstructorMetadataAnnotationImpl({
    required this.element,
    required this.annotationIndex,
    required super.id,
    required super.constructor,
    required super.type,
    required super.positionalArguments,
    required super.namedArguments,
  });
}

class DeclarationBuilder {
  final LinkedElementFactory elementFactory;
  final ast.AstNode? Function(Element?) nodeOfElement;

  final IdentifierImplVoid voidIdentifier = IdentifierImplVoid();
  final Map<Element, IdentifierImpl> _identifierMap = Map.identity();

  late final DeclarationBuilderFromNode fromNode =
      DeclarationBuilderFromNode(this);

  late final DeclarationBuilderFromElement fromElement =
      DeclarationBuilderFromElement(this);

  DeclarationBuilder({
    required this.elementFactory,
    required this.nodeOfElement,
  });

  Reference get rootReference {
    return elementFactory.rootReference;
  }

  TypeSystemImpl get _typeSystem {
    return elementFactory.analysisContext.typeSystem;
  }

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
      case ast.GenericTypeAliasImpl():
        return fromNode.typeAliasDeclaration(node);
      case ast.VariableDeclaration():
        return fromNode.variableDeclaration(node);
    }
    // TODO(scheglov): incomplete
    throw UnimplementedError('${node.runtimeType}');
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOf(macro.Identifier identifier) {
    if (identifier is! IdentifierImpl) {
      throw macro.MacroImplementationExceptionImpl(
        'Not analyzer identifier.',
        stackTrace: StackTrace.current.toString(),
      );
    }

    var element = identifier.element;
    if (element == null) {
      throw macro.MacroImplementationExceptionImpl(
        'Identifier without element.',
        stackTrace: StackTrace.current.toString(),
      );
    }

    return declarationOfElement(element);
  }

  /// See [macro.DefinitionPhaseIntrospector.declarationOf].
  macro.DeclarationImpl declarationOfElement(Element element) {
    var node = nodeOfElement(element);
    if (node != null) {
      return fromNode.declarationOf(node);
    } else {
      return fromElement.declarationOf(element);
    }
  }

  macro.IdentifierImpl identifierDeclared({
    required String name,
    required Element element,
  }) {
    return _identifierMap[element] ??= IdentifierImplDeclared(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.IdentifierImpl identifierFromElement({
    required String name,
    required Element element,
  }) {
    return _identifierMap[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.TypeAnnotation inferOmittedType(
    macro.OmittedTypeAnnotation omittedType,
  ) {
    var type = resolveType(omittedType.code);
    return fromElement._dartType(type);
  }

  macro.ResolvedIdentifier resolveIdentifier(macro.Identifier identifier) {
    if (identifier is IdentifierImplVoid) {
      return macro.ResolvedIdentifier(
        kind: macro.IdentifierKind.topLevelMember,
        name: 'void',
        uri: null,
        staticScope: null,
      );
    }

    identifier as IdentifierImpl;
    var element = identifier.element;
    switch (element) {
      case ConstructorElement():
        return macro.ResolvedIdentifier(
          kind: macro.IdentifierKind.staticInstanceMember,
          name: element.name,
          uri: element.library.source.uri,
          staticScope: element.enclosingElement3.name,
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
            staticScope: element.enclosingElement3.name,
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
            staticScope: element.enclosingElement3.name,
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
        if (element.enclosingElement3 is CompilationUnitElement) {
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
            staticScope: element.enclosingElement3.name,
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
      case null:
        throw ArgumentError('Unresolved identifier: ${identifier.name}');
      default:
        throw UnimplementedError('${element.runtimeType}');
    }
  }

  DartType resolveType(macro.TypeAnnotationCode typeCode) {
    switch (typeCode) {
      case macro.NullableTypeAnnotationCode():
        var type = resolveType(typeCode.underlyingType);
        type as TypeImpl;
        return type.withNullability(NullabilitySuffix.question);
      case macro.FunctionTypeAnnotationCode():
        return _resolveTypeCodeFunction(typeCode);
      case macro.NamedTypeAnnotationCode():
        return _resolveTypeCodeNamed(typeCode);
      case macro.OmittedTypeAnnotationCode():
        return _resolveTypeCodeOmitted(typeCode);
      case macro.RawTypeAnnotationCode():
        throw macro.MacroImplementationExceptionImpl(
          'Not supported',
          stackTrace: StackTrace.current.toString(),
        );
      case macro.RecordTypeAnnotationCode():
        return _resolveTypeCodeRecord(typeCode);
    }
  }

  /// See [macro.DeclarationPhaseIntrospector.typeDeclarationOf].
  macro.TypeDeclarationImpl typeDeclarationOf(macro.Identifier identifier) {
    if (identifier is! IdentifierImpl) {
      throw macro.MacroImplementationExceptionImpl(
        'Not analyzer identifier.',
        stackTrace: StackTrace.current.toString(),
      );
    }

    var element = identifier.element;
    if (element == null) {
      throw macro.MacroImplementationExceptionImpl(
        'Identifier without element.',
        stackTrace: StackTrace.current.toString(),
      );
    }

    var node = nodeOfElement(element);
    if (node != null) {
      return fromNode.typeDeclarationOf(node);
    } else {
      return fromElement.typeDeclarationOf(element);
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    var result = <macro.MetadataAnnotationImpl>[];
    for (var partialElement in element.withAugmentations) {
      partialElement as ElementImpl;
      var metadata = partialElement.metadata;
      for (var i = 0; i < metadata.length; i++) {
        result.addIfNotNull(
          _buildMetadataElement(
            element: partialElement,
            annotationIndex: i,
            annotation: metadata[i],
          ),
        );
      }
    }
    return result;
  }

  macro.MetadataAnnotationImpl? _buildMetadataElement({
    required ElementImpl element,
    required int annotationIndex,
    required ElementAnnotation annotation,
  }) {
    annotation as ElementAnnotationImpl;
    var node = annotation.annotationAst;

    var importPrefixNames = annotation.compilationUnit.withEnclosing
        .expand((fragment) => fragment.libraryImports)
        .map((e) => e.prefix?.element.name)
        .nonNulls
        .toSet();

    var identifiers = <ast.SimpleIdentifier>[];

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

    var identifierName = identifiers[nextIndex++];
    var constructorName = identifiers.elementAtOrNull(nextIndex);

    var identifierMacro = IdentifierImplFromNode(
      id: macro.RemoteInstance.uniqueId,
      name: identifierName.name,
      getElement: () => identifierName.staticElement,
    );

    var argumentList = node.arguments;
    if (argumentList != null) {
      var arguments = argumentList.arguments;
      return ConstructorMetadataAnnotationImpl(
        element: element,
        annotationIndex: annotationIndex,
        id: macro.RemoteInstance.uniqueId,
        constructor: IdentifierImplFromNode(
          id: macro.RemoteInstance.uniqueId,
          name: constructorName?.name ?? '',
          getElement: () => node.element,
        ),
        type: macro.NamedTypeAnnotationImpl(
            id: macro.RemoteInstance.uniqueId,
            isNullable: false,
            identifier: identifierMacro,
            // TODO(scheglov): Support type arguments for constructor
            // annotations.
            typeArguments: []),
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
      return IdentifierMetadataAnnotationImpl(
        element: element,
        annotationIndex: annotationIndex,
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
      var element = ParameterElementImpl(
        name: e.name,
        nameOffset: -1,
        parameterKind: getKind(e),
      );
      element.type = switch (e.type) {
        var type? => resolveType(type),
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
        var returnType? => resolveType(returnType),
        _ => DynamicTypeImpl.instance,
      },
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }

  DartType _resolveTypeCodeNamed(macro.NamedTypeAnnotationCode typeCode) {
    var identifier = typeCode.name as IdentifierImpl;
    if (identifier is IdentifierImplVoid) {
      return VoidTypeImpl.instance;
    }

    var element = identifier.element;
    switch (element) {
      case DynamicElementImpl():
        return DynamicTypeImpl.instance;
      case InterfaceElementImpl():
        if (typeCode.typeArguments.isEmpty) {
          return _typeSystem.instantiateInterfaceToBounds(
            element: element,
            nullabilitySuffix: NullabilitySuffix.none,
          );
        }
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
    var omittedType = typeCode.typeAnnotation;
    switch (omittedType) {
      case OmittedTypeAnnotationDynamic():
        return DynamicTypeImpl.instance;
      case OmittedTypeAnnotationFunctionReturnType():
        return omittedType.element.returnType;
      case OmittedTypeAnnotationVariable():
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
  final DeclarationBuilder builder;

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

  final Map<TypeAliasElementImpl, TypeAliasDeclarationImpl> _typeAliasMap =
      Map.identity();

  final Map<TypeParameterElementImpl, macro.TypeParameterDeclarationImpl>
      _typeParameterDeclarationMap = Map.identity();

  final Map<TypeParameterElement, macro.TypeParameterImpl> _typeParameterMap =
      Map.identity();

  final Map<TopLevelVariableElement, VariableDeclarationImpl> _variableMap =
      Map.identity();

  DeclarationBuilderFromElement(this.builder);

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
        if (element.enclosingElement3 is CompilationUnitElement) {
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
    var name = switch (element) {
      PropertyAccessorElement(isSetter: true) => element.displayName,
      _ => element.name!,
    };

    var map = builder._identifierMap;
    return map[element] ??= IdentifierImplFromElement(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.LibraryImpl library(Element element) {
    var libraryElement = element.library as LibraryElementImpl;
    var macroLibrary = _libraryMap[libraryElement];
    if (macroLibrary == null) {
      var version = libraryElement.languageVersion.effective;
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

  macro.TypeAliasDeclarationImpl typeAliasElement(
    TypeAliasElementImpl element,
  ) {
    return _typeAliasMap[element] ??= _typeAliasElement(element);
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
      case TypeAliasElementImpl():
        return typeAliasElement(element);
      default:
        // TODO(scheglov): other elements
        throw macro.MacroImplementationExceptionImpl(
          'element: (${element.runtimeType}) $element',
          stackTrace: StackTrace.current.toString(),
        );
    }
  }

  macro.TypeParameterImpl typeParameter(
    TypeParameterElement element,
  ) {
    return _typeParameterMap[element] ??= _typeParameter(element);
  }

  macro.TypeParameterDeclarationImpl typeParameterDeclaration(
    TypeParameterElement element,
  ) {
    element as TypeParameterElementImpl;
    return _typeParameterDeclarationMap[element] ??=
        _typeParameterDeclaration(element);
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return builder._buildMetadata(element);
  }

  ClassDeclarationImpl _classElement(
    ClassElementImpl element,
  ) {
    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(element.typeParameters),
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
    var enclosing = element.enclosingInstanceElement;
    return ConstructorDeclarationImpl._(
      element: element,
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: !element.isAbstract,
      hasExternal: element.isExternal,
      isConst: element.isConst,
      isFactory: element.isFactory,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: _typeParameterDeclarations(element.typeParameters),
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
              .map(_formalParameter)
              .toList(),
          positionalParameters: type.parameters
              .where((e) => e.isPositional)
              .map(_formalParameter)
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
          identifier: IdentifierImplVoid(),
          isNullable: false,
          typeArguments: const [],
        );
      default:
        // TODO(scheglov): implement other types
        throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  List<macro.TypeAnnotationImpl> _dartTypes(List<DartType> types) {
    return List.generate(types.length, (index) {
      var type = types[index];
      return _dartType(type);
    }, growable: false);
  }

  EnumValueDeclarationImpl _enumConstantElement(
    FieldElementImpl element,
  ) {
    var enclosing = element.enclosingElement3 as EnumElementImpl;
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
      typeParameters: _typeParameterDeclarations(element.typeParameters),
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
      typeParameters: _typeParameterDeclarations(element.typeParameters),
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
      typeParameters: _typeParameterDeclarations(element.typeParameters),
      representationType: _dartType(element.representation.type),
      element: element,
    );
  }

  FieldDeclarationImpl _fieldElement(FieldElementImpl element) {
    var enclosing = element.enclosingInstanceElement;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: element.isAbstract,
      hasConst: element.isConst,
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasInitializer: element.hasInitializer,
      hasLate: element.isLate,
      type: _dartType(element.type),
      definingType: identifier(enclosing),
      hasStatic: element.isStatic,
      element: element,
    );
  }

  macro.FormalParameterImpl _formalParameter(
    ParameterElement element,
  ) {
    return macro.FormalParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: element.isNamed,
      isRequired: element.isRequired,
      metadata: _buildMetadata(element),
      name: element.name,
      type: _dartType(element.type),
    );
  }

  macro.FormalParameterDeclarationImpl _formalParameterDeclaration(
      ParameterElement element) {
    return macro.FormalParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      isNamed: element.isNamed,
      isRequired: element.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      style: element.parameterStyle,
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
      typeParameters: _typeParameterDeclarations(element.typeParameters),
    );
  }

  macro.NamedTypeAnnotationImpl _interfaceType(InterfaceType type) {
    return macro.NamedTypeAnnotationImpl(
      id: macro.RemoteInstance.uniqueId,
      isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
      identifier: identifier(type.element),
      typeArguments: _dartTypes(type.typeArguments),
    );
  }

  MethodDeclarationImpl _methodElement(ExecutableElementImpl element) {
    var enclosing = element.enclosingInstanceElement;
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
      hasStatic: element.isStatic,
      namedParameters: _namedFormalParameters(element.parameters),
      positionalParameters: _positionalFormalParameters(element.parameters),
      returnType: _dartType(element.returnType),
      typeParameters: _typeParameterDeclarations(element.typeParameters),
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
      typeParameters: _typeParameterDeclarations(element.typeParameters),
      hasBase: element.isBase,
      interfaces: element.interfaces.map(_interfaceType).toList(),
      superclassConstraints:
          element.superclassConstraints.map(_interfaceType).toList(),
      element: element,
    );
  }

  List<macro.FormalParameterDeclarationImpl> _namedFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isNamed)
        .map(_formalParameterDeclaration)
        .toList();
  }

  List<macro.FormalParameterDeclarationImpl> _positionalFormalParameters(
    List<ParameterElement> elements,
  ) {
    return elements
        .where((element) => element.isPositional)
        .map(_formalParameterDeclaration)
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
      hasConst: element.isConst,
      hasExternal: element.isExternal,
      hasFinal: element.isFinal,
      hasInitializer: element.hasInitializer,
      hasLate: element.isLate,
      type: _dartType(element.type),
      element: element,
    );
  }

  TypeAliasDeclarationImpl _typeAliasElement(
    TypeAliasElementImpl element,
  ) {
    return TypeAliasDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      element: element,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      aliasedType: _dartType(element.aliasedType),
      typeParameters: _typeParameterDeclarations(element.typeParameters),
    );
  }

  macro.TypeParameterImpl _typeParameter(
    TypeParameterElement element,
  ) {
    return macro.TypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      name: identifier(element).name,
      metadata: _buildMetadata(element),
      bound: element.bound.mapOrNull(_dartType),
    );
  }

  macro.TypeParameterDeclarationImpl _typeParameterDeclaration(
    TypeParameterElementImpl element,
  ) {
    return TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: identifier(element),
      library: library(element),
      metadata: _buildMetadata(element),
      bound: element.bound.mapOrNull(_dartType),
      element: element,
    );
  }

  List<macro.TypeParameterDeclarationImpl> _typeParameterDeclarations(
    List<TypeParameterElement> elements,
  ) {
    return elements.map(typeParameterDeclaration).toList();
  }

  List<macro.TypeParameterImpl> _typeParameters(
    List<TypeParameterElement> elements,
  ) {
    return elements.map(typeParameter).toList();
  }
}

class DeclarationBuilderFromNode {
  final DeclarationBuilder builder;

  final Map<Element, LibraryImpl> _libraryMap = Map.identity();

  DeclarationBuilderFromNode(this.builder);

  ClassDeclarationImpl classDeclaration(
    ast.ClassDeclarationImpl node,
  ) {
    var element = node.declaredElement!;

    ast.ExtendsClause? extendsClause;
    var interfaceNodes = <ast.NamedType>[];
    var mixinNodes = <ast.NamedType>[];
    for (var current in node.withAugmentations(builder)) {
      extendsClause ??= current.extendsClause;
      if (current.implementsClause case var clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      if (current.withClause case var clause?) {
        mixinNodes.addAll(clause.mixinTypes);
      }
    }

    var classTypeLocation = ElementTypeLocation(element);

    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      interfaces: _namedTypes(
        interfaceNodes,
        ImplementsClauseTypeLocation(classTypeLocation),
      ),
      hasAbstract: node.abstractKeyword != null,
      hasBase: node.baseKeyword != null,
      hasExternal: false,
      hasFinal: node.finalKeyword != null,
      hasInterface: node.interfaceKeyword != null,
      hasMixin: node.mixinKeyword != null,
      hasSealed: node.sealedKeyword != null,
      mixins: _namedTypes(
        mixinNodes,
        WithClauseTypeLocation(classTypeLocation),
      ),
      superclass: extendsClause?.superclass.mapOrNull((type) {
        return _namedType(
          type,
          ExtendsClauseTypeLocation(classTypeLocation),
        );
      }),
      element: element,
    );
  }

  ClassDeclarationImpl classTypeAlias(
    ast.ClassTypeAliasImpl node,
  ) {
    var element = node.declaredElement!;

    var interfaceNodes = <ast.NamedType>[];
    var mixinNodes = <ast.NamedType>[];
    for (var current in node.withAugmentations(builder)) {
      if (current.implementsClause case var clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      mixinNodes.addAll(current.withClause.mixinTypes);
    }

    var classTypeLocation = ElementTypeLocation(element);

    return ClassDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      interfaces: _namedTypes(
        interfaceNodes,
        ImplementsClauseTypeLocation(classTypeLocation),
      ),
      hasAbstract: node.abstractKeyword != null,
      hasBase: node.baseKeyword != null,
      hasExternal: false,
      hasFinal: node.finalKeyword != null,
      hasInterface: node.interfaceKeyword != null,
      hasMixin: node.mixinKeyword != null,
      hasSealed: node.sealedKeyword != null,
      mixins: _namedTypes(
        mixinNodes,
        WithClauseTypeLocation(classTypeLocation),
      ),
      superclass: node.superclass.mapOrNull((type) {
        return _namedType(
          type,
          ExtendsClauseTypeLocation(classTypeLocation),
        );
      }),
      element: element,
    );
  }

  macro.ConstructorDeclarationImpl constructorDeclaration(
    ast.ConstructorDeclarationImpl node,
  ) {
    var definingType = _definingType(node);
    var element = node.declaredElement!;

    var (namedParameters, positionalParameters) =
        _executableFormalParameters(element, node.parameters);

    return ConstructorDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      isConst: node.constKeyword != null,
      isFactory: node.factoryKeyword != null,
      namedParameters: namedParameters,
      positionalParameters: positionalParameters,
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
    var element = node.declaredElement!;
    return _enumConstantDeclaration(element);
  }

  EnumDeclarationImpl enumDeclaration(
    ast.EnumDeclarationImpl node,
  ) {
    var element = node.declaredElement!;

    var interfaceNodes = <ast.NamedType>[];
    var mixinNodes = <ast.NamedType>[];
    for (var current in node.withAugmentations(builder)) {
      if (current.implementsClause case var clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
      if (current.withClause case var clause?) {
        mixinNodes.addAll(clause.mixinTypes);
      }
    }

    var enumTypeLocation = ElementTypeLocation(element);

    return EnumDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      interfaces: _namedTypes(
        interfaceNodes,
        ImplementsClauseTypeLocation(enumTypeLocation),
      ),
      mixins: _namedTypes(
        mixinNodes,
        WithClauseTypeLocation(enumTypeLocation),
      ),
      element: element,
    );
  }

  ExtensionDeclarationImpl extensionDeclaration(
    ast.ExtensionDeclarationImpl node,
  ) {
    var element = node.declaredElement!;

    var declarationElement = element.augmented.declaration;
    var declarationNode = builder.nodeOfElement(declarationElement)
        as ast.ExtensionDeclarationImpl;

    return ExtensionDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name?.lexeme ?? '', element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      onType: _typeAnnotation(
        declarationNode.onClause!.extendedType,
        ExtensionElementOnTypeLocation(element),
      ),
      element: element,
    );
  }

  ExtensionTypeDeclarationImpl extensionTypeDeclaration(
    ast.ExtensionTypeDeclarationImpl node,
  ) {
    var element = node.declaredElement!;

    return ExtensionTypeDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier2(node.name.lexeme, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      representationType: _typeAnnotation(
        node.representation.fieldType,
        ExtensionTypeElementRepresentationTypeLocation(element),
      ),
      element: element,
    );
  }

  macro.FunctionDeclarationImpl functionDeclaration(
    ast.FunctionDeclarationImpl node,
  ) {
    var element = node.declaredElement!;
    var function = node.functionExpression;

    var (namedParameters, positionalParameters) =
        _executableFormalParameters(element, function.parameters);

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
      namedParameters: namedParameters,
      positionalParameters: positionalParameters,
      returnType: _typeAnnotationFunctionReturnType(node),
      typeParameters: _typeParameterDeclarations(function.typeParameters),
    );
  }

  macro.LibraryImpl library(Element element) {
    var libraryElement = element.library as LibraryElementImpl;

    if (_libraryMap[libraryElement] case var result?) {
      return result;
    }

    var version = libraryElement.languageVersion.effective;
    var uri = libraryElement.source.uri;

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
    var element = node.element as LibraryElementImpl;
    return library(element);
  }

  macro.MethodDeclarationImpl methodDeclaration(
    ast.MethodDeclarationImpl node,
  ) {
    var definingType = _definingType(node);
    var element = node.declaredElement!;

    var (namedParameters, positionalParameters) =
        _executableFormalParameters(element, node.parameters);

    return MethodDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      definingType: definingType,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasBody: node.body is! ast.EmptyFunctionBody,
      hasExternal: node.externalKeyword != null,
      hasStatic: node.isStatic,
      isGetter: node.isGetter,
      isOperator: node.isOperator,
      isSetter: node.isSetter,
      namedParameters: namedParameters,
      positionalParameters: positionalParameters,
      returnType: _typeAnnotationMethodReturnType(node),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
    );
  }

  MixinDeclarationImpl mixinDeclaration(
    ast.MixinDeclarationImpl node,
  ) {
    var element = node.declaredElement!;

    var onNodes = <ast.NamedType>[];
    var interfaceNodes = <ast.NamedType>[];
    for (var current in node.withAugmentations(builder)) {
      if (current.onClause case var clause?) {
        onNodes.addAll(clause.superclassConstraints);
      }
      if (current.implementsClause case var clause?) {
        interfaceNodes.addAll(clause.interfaces);
      }
    }

    var mixinTypeLocation = ElementTypeLocation(element);

    return MixinDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
      hasBase: node.baseKeyword != null,
      interfaces: _namedTypes(
        interfaceNodes,
        ImplementsClauseTypeLocation(mixinTypeLocation),
      ),
      superclassConstraints: _namedTypes(
        onNodes,
        OnClauseTypeLocation(mixinTypeLocation),
      ),
      element: element,
    );
  }

  macro.FieldDeclarationImpl representationDeclaration(
    ast.RepresentationDeclaration node,
  ) {
    var element = node.fieldElement as FieldElementImpl;
    return FieldDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.fieldName, element),
      library: library(element),
      metadata: _buildMetadata(element),
      hasAbstract: false,
      hasConst: element.isConst,
      hasExternal: false,
      hasFinal: element.isFinal,
      hasInitializer: element.hasInitializer,
      hasLate: element.isLate,
      type: _typeAnnotationVariable(
        node.fieldType,
        element,
        ElementTypeLocation(element),
      ),
      definingType: _definingType(node),
      hasStatic: element.isStatic,
      element: element,
    );
  }

  macro.TypeAliasDeclarationImpl typeAliasDeclaration(
    ast.GenericTypeAliasImpl node,
  ) {
    var element = node.declaredElement as TypeAliasElementImpl;

    return TypeAliasDeclarationImpl._(
      id: macro.RemoteInstance.uniqueId,
      element: element,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      aliasedType: _typeAnnotationAliasedType(node),
      typeParameters: _typeParameterDeclarations(node.typeParameters),
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
      case ast.GenericTypeAliasImpl():
        return typeAliasDeclaration(node);
      case ast.MixinDeclarationImpl():
        return mixinDeclaration(node);
      default:
        // TODO(scheglov): other nodes
        throw macro.MacroImplementationExceptionImpl(
          'node: (${node.runtimeType}) $node',
          stackTrace: StackTrace.current.toString(),
        );
    }
  }

  macro.DeclarationImpl variableDeclaration(
    ast.VariableDeclaration node,
  ) {
    var variableList = node.parent as ast.VariableDeclarationList;
    var variablesDeclaration = variableList.parent;

    var element = node.declaredElement;
    if (element is FieldElementImpl && element.isEnumConstant) {
      return _enumConstantDeclaration(element);
    }

    switch (variablesDeclaration) {
      case ast.FieldDeclarationImpl():
        var element = node.declaredElement as FieldElementImpl;
        return FieldDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _declaredIdentifier(node.name, element),
          library: library(element),
          metadata: _buildMetadata(element),
          hasAbstract: variablesDeclaration.abstractKeyword != null,
          hasConst: element.isConst,
          hasExternal: variablesDeclaration.externalKeyword != null,
          hasFinal: element.isFinal,
          hasInitializer: element.hasInitializer,
          hasLate: element.isLate,
          type: _typeAnnotationVariable(
            variableList.type,
            element,
            ElementTypeLocation(element),
          ),
          definingType: _definingType(variablesDeclaration),
          hasStatic: element.isStatic,
          element: element,
        );
      case ast.TopLevelVariableDeclarationImpl():
        var element = node.declaredElement as TopLevelVariableElementImpl;
        return VariableDeclarationImpl(
          id: macro.RemoteInstance.uniqueId,
          identifier: _declaredIdentifier(node.name, element),
          library: library(element),
          metadata: _buildMetadata(element),
          hasConst: element.isConst,
          hasExternal: element.isExternal,
          hasFinal: element.isFinal,
          hasInitializer: element.hasInitializer,
          hasLate: element.isLate,
          type: _typeAnnotationVariable(
            variableList.type,
            element,
            ElementTypeLocation(element),
          ),
          element: element,
        );
      default:
        throw UnimplementedError('${variablesDeclaration.runtimeType}');
    }
  }

  List<macro.MetadataAnnotationImpl> _buildMetadata(Element element) {
    return builder._buildMetadata(element);
  }

  macro.IdentifierImpl _declaredIdentifier(Token name, Element element) {
    var map = builder._identifierMap;
    return map[element] ??= IdentifierImplDeclared(
      id: macro.RemoteInstance.uniqueId,
      name: name.lexeme,
      element: element,
    );
  }

  macro.IdentifierImpl _declaredIdentifier2(String name, Element element) {
    var map = builder._identifierMap;
    return map[element] ??= IdentifierImplDeclared(
      id: macro.RemoteInstance.uniqueId,
      name: name,
      element: element,
    );
  }

  macro.IdentifierImpl _definingType(ast.AstNode node) {
    var parentNode = node.parent;
    switch (parentNode) {
      case ast.ClassDeclaration():
        var parentElement = parentNode.declaredElement!;
        var typeElement = parentElement.augmented.declaration;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.EnumDeclaration():
        var parentElement = parentNode.declaredElement!;
        var typeElement = parentElement.augmented.declaration;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.ExtensionDeclaration():
        var parentElement = parentNode.declaredElement!;
        var typeElement = parentElement.augmented.declaration;
        return _declaredIdentifier2(parentNode.name?.lexeme ?? '', typeElement);
      case ast.ExtensionTypeDeclaration():
        var parentElement = parentNode.declaredElement!;
        var typeElement = parentElement.augmented.declaration;
        return _declaredIdentifier(parentNode.name, typeElement);
      case ast.MixinDeclaration():
        var parentElement = parentNode.declaredElement!;
        var typeElement = parentElement.augmented.declaration;
        return _declaredIdentifier(parentNode.name, typeElement);
      default:
        // TODO(scheglov): other parents
        throw UnimplementedError('(${parentNode.runtimeType}) $parentNode');
    }
  }

  macro.EnumValueDeclarationImpl _enumConstantDeclaration(
    FieldElementImpl element,
  ) {
    var enclosing = element.enclosingElement3 as EnumElementImpl;
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

  (
    List<macro.FormalParameterDeclarationImpl>,
    List<macro.FormalParameterDeclarationImpl>,
  ) _executableFormalParameters(
    ExecutableElement element,
    ast.FormalParameterList? node,
  ) {
    var named = <macro.FormalParameterDeclarationImpl>[];
    var positional = <macro.FormalParameterDeclarationImpl>[];
    if (node != null) {
      var elementLocation = ElementTypeLocation(element);
      for (var (index, node) in node.parameters.indexed) {
        var formalParameter = _formalParameterDeclaration(
          node,
          FormalParameterTypeLocation(elementLocation, index),
        );
        if (node.isNamed) {
          named.add(formalParameter);
        } else {
          positional.add(formalParameter);
        }
      }
    }
    return (named, positional);
  }

  macro.FormalParameterImpl _formalParameter(
    ast.FormalParameter node,
    TypeAnnotationLocation location,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    var element = node.declaredElement!;

    macro.TypeAnnotationImpl typeAnnotation;
    if (node is ast.SimpleFormalParameter) {
      typeAnnotation = _typeAnnotationOrDynamic(node.type, location);
    } else {
      throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FormalParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      metadata: _buildMetadata(element),
      name: node.name?.lexeme,
      type: typeAnnotation,
    );
  }

  macro.FormalParameterDeclarationImpl _formalParameterDeclaration(
    ast.FormalParameter node,
    TypeAnnotationLocation location,
  ) {
    if (node is ast.DefaultFormalParameter) {
      node = node.parameter;
    }

    var element = node.declaredElement!;

    macro.TypeAnnotationImpl typeAnnotation;
    switch (node) {
      case ast.FieldFormalParameter():
        typeAnnotation = _typeAnnotationVariable(node.type, element, location);
      case ast.SimpleFormalParameter():
        typeAnnotation = _typeAnnotationVariable(node.type, element, location);
      case ast.SuperFormalParameter():
        typeAnnotation = _typeAnnotationVariable(node.type, element, location);
      default:
        throw UnimplementedError('(${node.runtimeType}) $node');
    }

    return macro.FormalParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name!, element),
      isNamed: node.isNamed,
      isRequired: node.isRequired,
      library: library(element),
      metadata: _buildMetadata(element),
      style: element.parameterStyle,
      type: typeAnnotation,
    );
  }

  _FunctionTypeAnnotation _functionType(
    ast.GenericFunctionTypeImpl node,
    TypeAnnotationLocation location,
  ) {
    var namedParameters = <macro.FormalParameterImpl>[];
    var positionalParameters = <macro.FormalParameterImpl>[];
    var formalParameters = node.parameters.parameters;
    for (var (index, node) in formalParameters.indexed) {
      var formalParameter = _formalParameter(
        node,
        FormalParameterTypeLocation(location, index),
      );
      if (node.isNamed) {
        namedParameters.add(formalParameter);
      } else {
        positionalParameters.add(formalParameter);
      }
    }

    return _FunctionTypeAnnotation(
      id: macro.RemoteInstance.uniqueId,
      isNullable: node.question != null,
      namedParameters: namedParameters,
      positionalParameters: positionalParameters,
      returnType: _typeAnnotationOrDynamic(
        node.returnType,
        ReturnTypeLocation(location),
      ),
      typeParameters: _typeParameters(node.typeParameters),
      location: location,
    );
  }

  macro.NamedTypeAnnotationImpl _namedType(
    ast.NamedType node,
    TypeAnnotationLocation location,
  ) {
    return _NamedTypeAnnotation(
      id: macro.RemoteInstance.uniqueId,
      identifier: _namedTypeIdentifier(node),
      isNullable: node.question != null,
      typeArguments: _typeAnnotations(
        node.typeArguments?.arguments,
        location,
      ),
      location: location,
    );
  }

  macro.IdentifierImpl _namedTypeIdentifier(ast.NamedType node) {
    if (node.importPrefix == null && node.name2.lexeme == 'void') {
      return builder.voidIdentifier;
    }

    var element = node.element;
    if (element != null) {
      return builder._identifierMap[element] ??= IdentifierImplFromElement(
        id: macro.RemoteInstance.uniqueId,
        name: node.name2.lexeme,
        element: element,
      );
    }

    return _NamedTypeIdentifierImpl(
      id: macro.RemoteInstance.uniqueId,
      name: node.name2.lexeme,
      node: node,
    );
  }

  List<macro.NamedTypeAnnotationImpl> _namedTypes(
    List<ast.NamedType>? elements,
    TypeAnnotationLocation location,
  ) {
    if (elements != null) {
      return elements.indexed.map((pair) {
        return _namedType(
          pair.$2,
          ListIndexTypeLocation(location, pair.$1),
        );
      }).toList();
    } else {
      return const [];
    }
  }

  macro.TypeAnnotationImpl _typeAnnotation(
    ast.TypeAnnotation node,
    TypeAnnotationLocation location,
  ) {
    node as ast.TypeAnnotationImpl;
    switch (node) {
      case ast.GenericFunctionTypeImpl():
        return _functionType(node, location);
      case ast.NamedTypeImpl():
        return _namedType(node, location);
      case ast.RecordTypeAnnotationImpl():
        return _typeAnnotationRecord(node, location);
    }
  }

  macro.TypeAnnotationImpl _typeAnnotationAliasedType(
    ast.GenericTypeAliasImpl node,
  ) {
    var element = node.declaredElement as TypeAliasElementImpl;
    var location = AliasedTypeLocation(
      ElementTypeLocation(element),
    );

    return _typeAnnotation(node.type, location);
  }

  macro.TypeAnnotationImpl _typeAnnotationFunctionReturnType(
    ast.FunctionDeclaration node,
  ) {
    var element = node.declaredElement!;
    var location = ReturnTypeLocation(
      ElementTypeLocation(element),
    );

    var returnType = node.returnType;
    if (returnType == null) {
      return OmittedTypeAnnotationFunctionReturnType(element, location);
    }

    return _typeAnnotation(returnType, location);
  }

  macro.TypeAnnotationImpl _typeAnnotationMethodReturnType(
    ast.MethodDeclaration node,
  ) {
    var element = node.declaredElement!;

    var location = ReturnTypeLocation(
      ElementTypeLocation(element),
    );

    var returnType = node.returnType;
    if (returnType == null) {
      return OmittedTypeAnnotationFunctionReturnType(element, location);
    }

    return _typeAnnotation(returnType, location);
  }

  macro.TypeAnnotationImpl _typeAnnotationOrDynamic(
    ast.TypeAnnotation? node,
    TypeAnnotationLocation location,
  ) {
    if (node == null) {
      return OmittedTypeAnnotationDynamic(location);
    }
    return _typeAnnotation(node, location);
  }

  macro.RecordTypeAnnotationImpl _typeAnnotationRecord(
    ast.RecordTypeAnnotation node,
    TypeAnnotationLocation location,
  ) {
    macro.RecordFieldImpl buildField(
      ast.RecordTypeAnnotationField field,
      TypeAnnotationLocation location,
    ) {
      var name = field.name?.lexeme ?? '';
      return macro.RecordFieldImpl(
        id: macro.RemoteInstance.uniqueId,
        name: name,
        type: _typeAnnotationOrDynamic(field.type, location),
      );
    }

    return _RecordTypeAnnotation(
      id: macro.RemoteInstance.uniqueId,
      positionalFields: node.positionalFields.indexed.map((pair) {
        return buildField(
          pair.$2,
          RecordPositionalFieldTypeLocation(location, pair.$1),
        );
      }).toList(),
      namedFields: node.namedFields?.fields.indexed.map((pair) {
            return buildField(
              pair.$2,
              RecordNamedFieldTypeLocation(location, pair.$1),
            );
          }).toList() ??
          [],
      isNullable: node.question != null,
      location: location,
    );
  }

  List<macro.TypeAnnotationImpl> _typeAnnotations(
    List<ast.TypeAnnotation>? elements,
    TypeAnnotationLocation location,
  ) {
    if (elements != null) {
      return List.generate(elements.length, (index) {
        return _typeAnnotation(
          elements[index],
          ListIndexTypeLocation(location, index),
        );
      });
    } else {
      return const [];
    }
  }

  macro.TypeAnnotationImpl _typeAnnotationVariable(
    ast.TypeAnnotation? type,
    VariableElement element,
    TypeAnnotationLocation parentLocation,
  ) {
    var location = VariableTypeLocation(parentLocation);
    if (type == null) {
      return OmittedTypeAnnotationVariable(element, location);
    }
    return _typeAnnotation(type, location);
  }

  macro.TypeParameterImpl _typeParameter(
    ast.TypeParameter node,
  ) {
    var element = node.declaredElement!;
    return macro.TypeParameterImpl(
      id: macro.RemoteInstance.uniqueId,
      name: node.name.lexeme,
      metadata: _buildMetadata(element),
      bound: node.bound.mapOrNull((type) {
        return _typeAnnotation(
          type,
          TypeParameterBoundLocation(),
        );
      }),
    );
  }

  macro.TypeParameterDeclarationImpl _typeParameterDeclaration(
    ast.TypeParameterImpl node,
  ) {
    var element = node.declaredElement!;
    return TypeParameterDeclarationImpl(
      id: macro.RemoteInstance.uniqueId,
      identifier: _declaredIdentifier(node.name, element),
      library: library(element),
      metadata: _buildMetadata(element),
      bound: node.bound.mapOrNull((type) {
        return _typeAnnotation(
          type,
          TypeParameterBoundLocation(),
        );
      }),
      element: element,
    );
  }

  List<macro.TypeParameterDeclarationImpl> _typeParameterDeclarations(
    ast.TypeParameterListImpl? typeParameterList,
  ) {
    if (typeParameterList != null) {
      return typeParameterList.typeParameters
          .map(_typeParameterDeclaration)
          .toList();
    } else {
      return const [];
    }
  }

  List<macro.TypeParameterImpl> _typeParameters(
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
    required super.hasConst,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasInitializer,
    required super.hasLate,
    required super.type,
    required super.definingType,
    required super.hasStatic,
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

class IdentifierImplDeclared extends IdentifierImpl {
  @override
  final Element element;

  IdentifierImplDeclared({
    required super.id,
    required super.name,
    required this.element,
  });
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

class IdentifierImplVoid extends IdentifierImpl {
  IdentifierImplVoid()
      : super(
          id: macro.RemoteInstance.uniqueId,
          name: 'void',
        );

  @override
  Element? get element => null;
}

class IdentifierMetadataAnnotationImpl extends macro
    .IdentifierMetadataAnnotationImpl implements MetadataAnnotationImpl {
  @override
  final ElementImpl element;

  @override
  final int annotationIndex;

  IdentifierMetadataAnnotationImpl({
    required this.element,
    required this.annotationIndex,
    required super.id,
    required super.identifier,
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
  final LibraryElementImpl element;

  LibraryImplFromElement({
    required super.id,
    required super.languageVersion,
    required super.metadata,
    required super.uri,
    required this.element,
  });
}

sealed class MetadataAnnotationImpl implements macro.MetadataAnnotationImpl {
  int get annotationIndex;

  ElementImpl get element;
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
    required super.hasStatic,
    required super.isGetter,
    required super.isOperator,
    required super.isSetter,
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

sealed class OmittedTypeAnnotation extends macro.OmittedTypeAnnotationImpl {
  OmittedTypeAnnotation()
      : super(
          id: macro.RemoteInstance.uniqueId,
        );
}

class OmittedTypeAnnotationDynamic extends OmittedTypeAnnotation
    implements TypeAnnotationWithLocation {
  @override
  final TypeAnnotationLocation location;

  OmittedTypeAnnotationDynamic(this.location);
}

class OmittedTypeAnnotationFunctionReturnType extends OmittedTypeAnnotation
    implements TypeAnnotationWithLocation {
  final ExecutableElement element;

  @override
  final TypeAnnotationLocation location;

  OmittedTypeAnnotationFunctionReturnType(this.element, this.location);
}

class OmittedTypeAnnotationVariable extends OmittedTypeAnnotation
    implements TypeAnnotationWithLocation {
  final VariableElement element;

  @override
  final TypeAnnotationLocation location;

  OmittedTypeAnnotationVariable(this.element, this.location);
}

class TypeAliasDeclarationImpl extends macro.TypeAliasDeclarationImpl
    implements HasElement {
  @override
  final TypeAliasElementImpl element;

  TypeAliasDeclarationImpl._({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.typeParameters,
    required super.aliasedType,
    required this.element,
  });
}

abstract class TypeAnnotationWithLocation implements macro.TypeAnnotation {
  TypeAnnotationLocation get location;
}

class TypeParameterDeclarationImpl extends macro.TypeParameterDeclarationImpl
    implements HasElement {
  @override
  final TypeParameterElementImpl element;

  TypeParameterDeclarationImpl({
    required super.id,
    required super.identifier,
    required super.library,
    required super.metadata,
    required super.bound,
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
    required super.hasConst,
    required super.hasExternal,
    required super.hasFinal,
    required super.hasInitializer,
    required super.hasLate,
    required super.type,
    required this.element,
  });
}

class _FunctionTypeAnnotation extends macro.FunctionTypeAnnotationImpl
    implements TypeAnnotationWithLocation {
  @override
  final TypeAnnotationLocation location;

  _FunctionTypeAnnotation({
    required super.id,
    required super.isNullable,
    required super.namedParameters,
    required super.positionalParameters,
    required super.returnType,
    required super.typeParameters,
    required this.location,
  });
}

class _NamedTypeAnnotation extends macro.NamedTypeAnnotationImpl
    implements TypeAnnotationWithLocation {
  @override
  final TypeAnnotationLocation location;

  _NamedTypeAnnotation({
    required super.id,
    required super.isNullable,
    required super.identifier,
    required super.typeArguments,
    required this.location,
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

class _RecordTypeAnnotation extends macro.RecordTypeAnnotationImpl
    implements TypeAnnotationWithLocation {
  @override
  final TypeAnnotationLocation location;

  _RecordTypeAnnotation({
    required super.id,
    required super.isNullable,
    required super.namedFields,
    required super.positionalFields,
    required this.location,
  });
}

extension on Element {
  /// With the assumption that enclosing element is an [InstanceElement], and
  /// is not an invalid augmentation, return the declaration - the start of
  /// the augmentation chain.
  InstanceElement get enclosingInstanceElement {
    var enclosing = enclosingElement3 as InstanceElement;
    return enclosing.augmented.declaration;
  }
}

extension on ParameterElement {
  /// Returns the [macro.ParameterStyle] for this element.
  macro.ParameterStyle get parameterStyle => switch (this) {
        ParameterElement(isInitializingFormal: true) =>
          macro.ParameterStyle.fieldFormal,
        ParameterElement(isSuperFormal: true) =>
          macro.ParameterStyle.superFormal,
        _ => macro.ParameterStyle.normal,
      };
}

extension<T extends ast.DeclarationImpl> on T {
  List<T> withAugmentations(DeclarationBuilder builder) {
    var result = <T>[];
    for (var current = this;;) {
      result.add(current);
      var nextElement = current.declaredElement
          .ifTypeOrNull<AugmentableElement>()
          ?.augmentation;
      var nextNode = builder.nodeOfElement(nextElement);
      if (nextNode is! T) {
        break;
      }
      current = nextNode;
    }
    return result;
  }
}

extension<T> on T? {
  R? mapOrNull<R>(R Function(T) mapper) {
    var self = this;
    return self != null ? mapper(self) : null;
  }
}
