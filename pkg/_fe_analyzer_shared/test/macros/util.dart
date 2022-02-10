// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:_fe_analyzer_shared/src/macros/api.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor_shared/remote_instance.dart';

import 'package:test/fake.dart';
import 'package:test/test.dart';

class FakeClassIntrospector extends Fake implements ClassIntrospector {}

class TestClassIntrospector implements ClassIntrospector {
  final Map<ClassDeclaration, List<ConstructorDeclaration>> constructors;
  final Map<ClassDeclaration, List<FieldDeclaration>> fields;
  final Map<ClassDeclaration, List<ClassDeclarationImpl>> interfaces;
  final Map<ClassDeclaration, List<ClassDeclarationImpl>> mixins;
  final Map<ClassDeclaration, List<MethodDeclaration>> methods;
  final Map<ClassDeclaration, ClassDeclaration?> superclass;

  TestClassIntrospector({
    required this.constructors,
    required this.fields,
    required this.interfaces,
    required this.mixins,
    required this.methods,
    required this.superclass,
  });

  @override
  Future<List<ConstructorDeclaration>> constructorsOf(
          covariant ClassDeclaration clazz) async =>
      constructors[clazz]!;

  @override
  Future<List<FieldDeclaration>> fieldsOf(
          covariant ClassDeclaration clazz) async =>
      fields[clazz]!;

  @override
  Future<List<ClassDeclaration>> interfacesOf(
          covariant ClassDeclaration clazz) async =>
      interfaces[clazz]!;

  @override
  Future<List<MethodDeclaration>> methodsOf(
          covariant ClassDeclaration clazz) async =>
      methods[clazz]!;

  @override
  Future<List<ClassDeclaration>> mixinsOf(
          covariant ClassDeclaration clazz) async =>
      mixins[clazz]!;

  @override
  Future<ClassDeclaration?> superclassOf(
          covariant ClassDeclaration clazz) async =>
      superclass[clazz];
}

class FakeTypeDeclarationResolver extends Fake
    implements TypeDeclarationResolver {}

class TestTypeDeclarationResolver implements TypeDeclarationResolver {
  final Map<Identifier, TypeDeclaration> typeDeclarations;

  TestTypeDeclarationResolver(this.typeDeclarations);

  @override
  Future<TypeDeclaration> declarationOf(
          covariant Identifier identifier) async =>
      typeDeclarations[identifier]!;
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

/// An identifier that knows the resolved version of itself.
class TestIdentifier extends IdentifierImpl {
  final ResolvedIdentifier resolved;

  TestIdentifier({
    required int id,
    required String name,
    required IdentifierKind kind,
    required Uri uri,
    required String? staticScope,
  })  : resolved = ResolvedIdentifier(
            kind: kind, name: name, staticScope: staticScope, uri: uri),
        super(
          id: id,
          name: name,
        );
}

extension DebugCodeString on Code {
  StringBuffer debugString([StringBuffer? buffer]) {
    buffer ??= StringBuffer();
    for (var part in parts) {
      if (part is Code) {
        part.debugString(buffer);
      } else if (part is IdentifierImpl) {
        buffer.write(part.name);
      } else {
        buffer.write(part as String);
      }
    }
    return buffer;
  }
}

/// Checks if two [Code] objectss are of the same type and all their fields are
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

/// Checks if two [Declaration]s, [TypeAnnotation]s, or [Code] objects are of
/// the same type and all their fields are equal.
class _DeepEqualityMatcher extends Matcher {
  final Object? instance;

  _DeepEqualityMatcher(this.instance);

  @override
  Description describe(Description description) => description;

  @override
  bool matches(item, Map matchState) {
    if (item.runtimeType != instance.runtimeType) {
      return false;
    }

    if (instance is Declaration || instance is TypeAnnotation) {
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

        // Handle lists of things
        if (instanceValue is List) {
          if (!_listEquals(instanceValue, itemValue, matchState)) {
            return false;
          }
        } else if (instanceValue is Declaration ||
            instanceValue is Code ||
            instanceValue is TypeAnnotation) {
          // Handle nested declarations and code objects
          if (!_DeepEqualityMatcher(instanceValue)
              .matches(itemValue, matchState)) {
            return false;
          }
        } else {
          // Handles basic values and identity
          if (instanceValue != itemValue) {
            return false;
          }
        }
      }
    } else if (instance is Code) {
      if (!_listEquals(
          (instance as Code).parts, (item as Code).parts, matchState)) {
        return false;
      }
    } else {
      // Handles basic values and identity
      if (instance != item) {
        return false;
      }
    }
    return true;
  }

  bool _listEquals(List instanceValue, List itemValue, Map matchState) {
    if (instanceValue.length != itemValue.length) {
      return false;
    }
    for (var i = 0; i < instanceValue.length; i++) {
      if (!_DeepEqualityMatcher(instanceValue[i])
          .matches(itemValue[i], matchState)) {
        return false;
      }
    }
    return true;
  }
}

class Fixtures {
  static final stringType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'String'),
      isNullable: false,
      typeArguments: const []);
  static final voidType = NamedTypeAnnotationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'void'),
      isNullable: false,
      typeArguments: const []);

  // Top level, non-class declarations.
  static final myFunction = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myFunction'),
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
      isExternal: false,
      isFinal: true,
      isLate: false,
      type: stringType);
  static final myVariableGetter = FunctionDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myVariable'),
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
            isNamed: false,
            isRequired: true,
            type: stringType)
      ],
      returnType: voidType,
      typeParameters: []);

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
  static final myClass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myClassType.identifier,
      typeParameters: [],
      interfaces: [myInterfaceType],
      isAbstract: false,
      isExternal: false,
      mixins: [myMixinType],
      superclass: mySuperclassType);
  static final myConstructor = ConstructorDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier:
          IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myConstructor'),
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: myClassType,
      typeParameters: [],
      definingClass: myClassType.identifier,
      isFactory: false);
  static final myField = FieldDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myField'),
      isExternal: false,
      isFinal: false,
      isLate: false,
      type: stringType,
      definingClass: myClassType.identifier);
  static final myInterface = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myInterfaceType.identifier,
      typeParameters: [],
      interfaces: [],
      isAbstract: false,
      isExternal: false,
      mixins: [],
      superclass: null);
  static final myMethod = MethodDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'myMethod'),
      isAbstract: false,
      isExternal: false,
      isGetter: false,
      isOperator: false,
      isSetter: false,
      namedParameters: [],
      positionalParameters: [],
      returnType: stringType,
      typeParameters: [],
      definingClass: myClassType.identifier);
  static final myMixin = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: myMixinType.identifier,
      typeParameters: [],
      interfaces: [],
      isAbstract: false,
      isExternal: false,
      mixins: [],
      superclass: null);
  static final mySuperclass = ClassDeclarationImpl(
      id: RemoteInstance.uniqueId,
      identifier: mySuperclassType.identifier,
      typeParameters: [],
      interfaces: [],
      isAbstract: false,
      isExternal: false,
      mixins: [],
      superclass: null);

  static final myClassStaticType = TestNamedStaticType(
      myClassType.identifier, 'package:my_package/my_package.dart', []);

  static final testTypeResolver = TestTypeResolver({
    stringType.identifier:
        TestNamedStaticType(stringType.identifier, 'dart:core', []),
    myClass.identifier: myClassStaticType,
  });
  static final testClassIntrospector = TestClassIntrospector(
    constructors: {
      myClass: [myConstructor],
    },
    fields: {
      myClass: [myField],
    },
    interfaces: {
      myClass: [myInterface],
    },
    methods: {
      myClass: [myMethod],
    },
    mixins: {
      myClass: [myMixin],
    },
    superclass: {
      myClass: mySuperclass,
    },
  );
  static final testTypeDeclarationResolver =
      TestTypeDeclarationResolver({myClass.identifier: myClass});
}
