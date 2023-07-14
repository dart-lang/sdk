// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';

import 'package:test/fake.dart';
import 'package:test/test.dart';

class FakeTypeIntrospector extends Fake implements TypeIntrospector {}

class TestTypeIntrospector implements TypeIntrospector {
  final Map<IntrospectableType, List<ConstructorDeclaration>> constructors;
  final Map<IntrospectableEnum, List<EnumValueDeclaration>> enumValues;
  final Map<IntrospectableType, List<FieldDeclaration>> fields;
  final Map<IntrospectableType, List<MethodDeclaration>> methods;
  final Map<Library, List<TypeDeclaration>> libraryTypes;

  TestTypeIntrospector({
    required this.constructors,
    required this.enumValues,
    required this.fields,
    required this.methods,
    required this.libraryTypes,
  });

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
          covariant IntrospectableType type) async =>
      constructors[type]!;

  @override
  Future<List<EnumValueDeclaration>> valuesOf(
          covariant IntrospectableEnum enuum) async =>
      enumValues[enuum]!;

  @override
  Future<List<FieldDeclaration>> fieldsOf(
          covariant IntrospectableType clazz) async =>
      fields[clazz]!;

  @override
  Future<List<MethodDeclaration>> methodsOf(
          covariant IntrospectableType clazz) async =>
      methods[clazz]!;

  @override
  Future<List<TypeDeclaration>> typesOf(covariant Library library) async =>
      libraryTypes[library]!;
}

class FakeIdentifierResolver implements IdentifierResolver {
  @override
  Future<Identifier> resolveIdentifier(Uri library, String name) async {
    if (library == Uri.parse('dart:core') && name == 'String') {
      return Fixtures.stringType.identifier;
    }
    throw UnimplementedError('Cannot resolve the identifier $library:$name');
  }
}

class FakeTypeDeclarationResolver extends Fake
    implements TypeDeclarationResolver {}

class TestTypeDeclarationResolver implements TypeDeclarationResolver {
  final Map<Identifier, TypeDeclaration> typeDeclarations;

  TestTypeDeclarationResolver(this.typeDeclarations);

  @override
  Future<TypeDeclaration> declarationOf(covariant Identifier identifier) async {
    var declaration = typeDeclarations[identifier];
    if (declaration != null) return declaration;
    throw 'No declaration found for ${identifier.name}';
  }
}

class TestTypeResolver implements TypeResolver {
  final Map<Identifier, StaticType> staticTypes;

  TestTypeResolver(this.staticTypes);

  @override
  Future<StaticType> resolve(covariant TypeAnnotationCode type) async {
    assert(type.parts.length == 1);
    return staticTypes[type.parts.first]!;
  }
}

/// Doesn't handle generics etc but thats ok for now
class TestNamedStaticType implements NamedStaticType {
  final IdentifierImpl identifier;
  final String library;
  final List<TestNamedStaticType> superTypes;

  TestNamedStaticType(this.identifier, this.library, this.superTypes);

  @override
  Future<bool> isExactly(TestNamedStaticType other) async => _isExactly(other);

  @override
  Future<bool> isSubtypeOf(TestNamedStaticType other) async =>
      _isExactly(other) ||
      superTypes.any((superType) => superType._isExactly(other));

  bool _isExactly(TestNamedStaticType other) =>
      identical(other, this) ||
      (library == other.library && identifier.name == other.identifier.name);
}

/// Assumes all omitted types are [TestOmittedTypeAnnotation]s and just returns
/// the inferred type directly.
class TestTypeInferrer implements TypeInferrer {
  @override
  Future<TypeAnnotation> inferType(
          TestOmittedTypeAnnotation omittedType) async =>
      omittedType.inferredType!;
}

/// Knows its inferred type ahead of time.
class TestOmittedTypeAnnotation extends OmittedTypeAnnotationImpl {
  final TypeAnnotation? inferredType;

  TestOmittedTypeAnnotation([this.inferredType])
      : super(id: RemoteInstance.uniqueId);
}

/// An identifier that knows the resolved version of itself.
class TestIdentifier extends IdentifierImpl {
  final ResolvedIdentifier resolved;

  TestIdentifier({
    required super.id,
    required super.name,
    required IdentifierKind kind,
    required Uri uri,
    required String? staticScope,
  }) : resolved = ResolvedIdentifier(
            kind: kind, name: name, staticScope: staticScope, uri: uri);
}

class TestLibraryDeclarationsResolver implements LibraryDeclarationsResolver {
  final Map<Library, List<Declaration>> libraryDeclarations;

  TestLibraryDeclarationsResolver(this.libraryDeclarations);

  @override
  Future<List<Declaration>> topLevelDeclarationsOf(
          covariant Library library) async =>
      libraryDeclarations[library]!;
}

extension DebugCodeString on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else if (part is IdentifierImpl) {
        buffer.write(part.name);
      } else if (part is TestOmittedTypeAnnotation) {
        if (part.inferredType != null) {
          buffer.write('/*inferred*/');
          part.inferredType!.code.debugString(buffer);
        } else {
          buffer.write('/*omitted*/');
        }
      } else {
        buffer.write(part as String);
      }
    }
    return buffer;
  }
}

/// Checks if two [Code] objects are of the same type and all their fields are
/// equal.
Matcher deepEqualsCode(Code other) => _DeepEqualityMatcher(other);

/// Checks if two [Declaration]s are of the same type and all their fields are
/// equal.
Matcher deepEqualsDeclaration(Declaration declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [TypeAnnotation]s are of the same type and all their fields
/// are equal.
Matcher deepEqualsTypeAnnotation(TypeAnnotation declaration) =>
    _DeepEqualityMatcher(declaration);

/// Checks if two [Arguments]s are identical
Matcher deepEqualsArguments(Arguments arguments) =>
    _DeepEqualityMatcher(arguments);

/// Checks if two [MetadataAnnotation]s are identical
Matcher deepEqualsMetadataAnnotation(MetadataAnnotation metadata) =>
    _DeepEqualityMatcher(metadata);

/// Checks if two [Declaration]s, [TypeAnnotation]s, or [Code] objects are of
/// the same type and all their fields are equal.
class _DeepEqualityMatcher extends Matcher {
  final Object? instance;

  _DeepEqualityMatcher(this.instance);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) {
    // For type promotion.
    final instance = this.instance;
    if (!equals(item.runtimeType).matches(instance.runtimeType, matchState)) {
      return false;
    }
    if (instance is Declaration ||
        instance is TypeAnnotation ||
        instance is MetadataAnnotation) {
      var instanceReflector = reflect(instance);
      var itemReflector = reflect(item);

      var type = instanceReflector.type;
      for (var getter
          in type.instanceMembers.values.where((member) => member.isGetter)) {
        // We only care about synthetic field getters
        if (!getter.isSynthetic) continue;

        var instanceField = instanceReflector.getField(getter.simpleName);
        var itemField = itemReflector.getField(getter.simpleName);
        var instanceValue = instanceField.reflectee;
        var itemValue = itemField.reflectee;

        if (!_DeepEqualityMatcher(instanceValue)
            .matches(itemValue, matchState)) {
          return false;
        }
      }
    } else if (instance is Code) {
      item as Code;
      if (!_DeepEqualityMatcher(instance.parts)
          .matches(item.parts, matchState)) {
        return false;
      }
    } else if (instance is Arguments) {
      item as Arguments;
      if (!equals(instance.positional.length)
          .matches(item.positional.length, matchState)) {
        return false;
      }
      for (var i = 0; i < instance.positional.length; i++) {
        if (!_DeepEqualityMatcher(instance.positional[i].value)
            .matches(item.positional[i].value, matchState)) {
          return false;
        }
      }
      if (instance.named.length != item.named.length) return false;
      if (!equals(instance.named.keys).matches(item.named.keys, matchState)) {
        return false;
      }
      for (var key in instance.named.keys) {
        if (!_DeepEqualityMatcher(instance.named[key]!.value)
            .matches(item.named[key]!.value, matchState)) {
          return false;
        }
      }
    } else if (instance is List) {
      item as List;
      if (!equals(instance.length).matches(item.length, matchState)) {
        return false;
      }
      for (var i = 0; i < instance.length; i++) {
        if (!_DeepEqualityMatcher(instance[i]).matches(item[i], matchState)) {
          return false;
        }
      }
    } else {
      // Handles basic values and identity
      if (!equals(instance).matches(item, matchState)) {
        return false;
      }
    }
    return true;
  }
}

class Fixtures {
  static final library = LibraryImpl(
      id: RemoteInstance.uniqueId,
      languageVersion: LanguageVersionImpl(3, 0),
      metadata: [],
      uri: Uri.parse('package:foo/bar.dart'));
  static final nullableBoolType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'bool'),
      isNullable: true,
      typeArguments: const []);
  static final stringType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'String'),
      isNullable: false,
      typeArguments: const []);
  static final inferredStringType = TestOmittedTypeAnnotation(stringType);
  static final voidType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'void'),
      isNullable: false,
      typeArguments: const []);
  static final recordType = RecordTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      isNullable: false,
      namedFields: [
        RecordFieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'world'),
            library: Fixtures.library,
            metadata: [],
            name: 'world',
            type: stringType),
      ],
      positionalFields: [
        RecordFieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: r'$1'),
            library: Fixtures.library,
            metadata: [],
            name: null,
            type: stringType),
        RecordFieldDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: r'$2'),
            library: Fixtures.library,
            metadata: [],
            name: 'hello',
            type: nullableBoolType),
      ]);

  // Top level, non-class declarations.
  static final myFunction = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myFunction'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: stringType,
      typeParameters: []);
  static final myVariable = VariableDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: '_myVariable'),
      library: Fixtures.library,
      metadata: [],
      isExternal: false,
      isFinal: true,
      isLate: false,
      type: inferredStringType);
  static final myVariableGetter = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myVariable'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: true,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: stringType,
      typeParameters: []);
  static final myVariableSetter = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myVariable'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: true,
      namedParameters: [],
      positionalParameters: [
        ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'value'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: stringType)
      ],
      returnType: voidType,
      typeParameters: []);

  static final libraryVariable = VariableDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'library'),
      library: Fixtures.library,
      metadata: [],
      isExternal: false,
      isFinal: true,
      isLate: false,
      type: NamedTypeAnnotationImpl(
          id: RemoteInstance.uniqueId,
          isNullable: false,
          identifier:
              IdentifierImpl(id: RemoteInstance.uniqueId, name: 'LibraryInfo'),
          typeArguments: []));

  // Class and member declarations
  static final myInterfaceType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyInterface'),
      isNullable: false,
      typeArguments: const []);
  static final myMixinType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyMixin'),
      isNullable: false,
      typeArguments: const []);
  static final mySuperclassType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MySuperclass'),
      isNullable: false,
      typeArguments: const []);
  static final myClassType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyClass'),
      isNullable: false,
      typeArguments: const []);
  static final myClass = IntrospectableClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myClassType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [myInterfaceType],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: false,
      hasMixin: false,
      hasSealed: false,
      mixins: [myMixinType],
      superclass: mySuperclassType);
  static final myConstructor = ConstructorDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myConstructor'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [
        ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: TestOmittedTypeAnnotation(myField.type))
      ],
      returnType: myClassType,
      typeParameters: [],
      definingType: myClassType.identifier,
      isFactory: false);
  static final myField = FieldDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
      library: Fixtures.library,
      metadata: [],
      isExternal: false,
      isFinal: false,
      isLate: false,
      type: stringType,
      definingType: myClassType.identifier,
      isStatic: false);
  static final myInterface = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myInterfaceType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: true,
      hasMixin: false,
      hasSealed: false,
      mixins: [],
      superclass: null);
  static final myMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myMethod'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: recordType,
      typeParameters: [],
      definingType: myClassType.identifier,
      isStatic: false);
  static final mySuperclass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: mySuperclassType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      hasAbstract: false,
      hasBase: false,
      hasExternal: false,
      hasFinal: false,
      hasInterface: false,
      hasMixin: false,
      hasSealed: false,
      mixins: [],
      superclass: null);

  static final myClassStaticType = TestNamedStaticType(
      myClassType.identifier, 'package:my_package/my_package.dart', []);

  static final myEnumType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      isNullable: false,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'MyEnum'),
      typeArguments: []);
  static final myEnum = IntrospectableEnumDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myEnumType.identifier,
      library: Fixtures.library,
      metadata: [],
      typeParameters: [],
      interfaces: [],
      mixins: []);
  static final myEnumValues = [
    EnumValueDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'a'),
      library: Fixtures.library,
      metadata: [],
      definingEnum: myEnum.identifier,
    ),
  ];
  static final myEnumConstructor = ConstructorDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(
          id: RemoteInstance.uniqueId, name: 'myEnumConstructor'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [
        ParameterDeclarationImpl(
            id: RemoteInstance.uniqueId,
            identifier:
                IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
            library: Fixtures.library,
            metadata: [],
            isNamed: false,
            isRequired: true,
            type: stringType)
      ],
      returnType: myEnumType,
      typeParameters: [],
      definingType: myEnum.identifier,
      isFactory: false);

  static final myMixin = IntrospectableMixinDeclarationImpl(
    id: RemoteInstance.uniqueId,
    identifier: myMixinType.identifier,
    library: Fixtures.library,
    metadata: [],
    typeParameters: [],
    hasBase: false,
    interfaces: [],
    superclassConstraints: [myClassType],
  );
  static final myMixinMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myMixinMethod'),
      library: Fixtures.library,
      metadata: [],
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: recordType,
      typeParameters: [],
      definingType: myMixinType.identifier,
      isStatic: false);

  static final testTypeResolver = TestTypeResolver({
    stringType.identifier:
        TestNamedStaticType(stringType.identifier, 'dart:core', []),
    myClass.identifier: myClassStaticType,
  });
  static final testTypeIntrospector = TestTypeIntrospector(constructors: {
    myClass: [myConstructor],
    myEnum: [myEnumConstructor],
    myMixin: [],
  }, enumValues: {
    myEnum: myEnumValues,
  }, fields: {
    myClass: [myField],
    myMixin: [],
    myEnum: [],
  }, methods: {
    myClass: [myMethod],
    myMixin: [myMixinMethod],
    myEnum: [],
  }, libraryTypes: {
    Fixtures.library: [
      myClass,
      myEnum,
      myMixin,
    ],
  });
  static final testTypeDeclarationResolver = TestTypeDeclarationResolver({
    myClass.identifier: myClass,
    myEnum.identifier: myEnum,
    mySuperclass.identifier: mySuperclass,
    myInterface.identifier: myInterface,
    myMixin.identifier: myMixin
  });

  static final testTypeInferrer = TestTypeInferrer();

  static final testLibraryDeclarationsResolver =
      TestLibraryDeclarationsResolver({
    Fixtures.library: [
      myClass,
      myEnum,
      myMixin,
      myFunction,
      myVariable,
      libraryVariable,
    ],
  });
}
