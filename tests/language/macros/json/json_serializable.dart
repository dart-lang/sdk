// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package

// There is no public API exposed yet, the in-progress API lives here.
import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class JsonSerializable implements ClassDeclarationsMacro {
  const JsonSerializable();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    var constructors = await builder.constructorsOf(clazz);
    if (constructors.any((c) => c.identifier.name == 'fromJson')) {
      throw ArgumentError('There is already a `fromJson` constructor for '
          '`${clazz.identifier.name}`, so one could not be added.');
    }

    var map = await builder.resolveIdentifier(_dartCore, 'Map');
    var string = NamedTypeAnnotationCode(
        name: await builder.resolveIdentifier(_dartCore, 'String'));
    var object = NamedTypeAnnotationCode(
        name: await builder.resolveIdentifier(_dartCore, 'Object'));
    var mapStringObject = NamedTypeAnnotationCode(
      name: map, typeArguments: [string, object.asNullable]);

    // TODO: This only works because the macro file lives right next to the file
    // it is applied to.
    var jsonSerializableUri =
        clazz.library.uri.resolve('json_serializable.dart');

    builder.declareInType(DeclarationCode.fromParts([
      '  @',
      await builder.resolveIdentifier(jsonSerializableUri, 'FromJson'),
      // TODO(language#3580): Remove/replace 'external'?
      '()\n  external ',
      clazz.identifier.name,
      '.fromJson(',
      mapStringObject,
      ' json);',
    ]));

    builder.declareInType(DeclarationCode.fromParts([
      '  @',
      await builder.resolveIdentifier(jsonSerializableUri, 'ToJson'),
      // TODO(language#3580): Remove/replace 'external'?
      '()\n  external ',
      mapStringObject,
      ' toJson();',
    ]));
  }
}

/// A macro applied to a fromJson constructor, which fills in the initializer list.
macro class FromJson implements ConstructorDefinitionMacro {
  const FromJson();

  @override
  Future<void> buildDefinitionForConstructor(ConstructorDeclaration constructor,
      ConstructorDefinitionBuilder builder) async {
    // TODO: Validate we are running on a valid fromJson constructor.

    // TODO: support extending other classes.
    var clazz = (await builder.typeDeclarationOf(constructor.definingType))
        as ClassDeclaration;
    var superclass = clazz.superclass;
    var superclassHasFromJson = false;
    var fromJsonData = await _FromJsonData.build(builder);
    if (superclass != null &&
        !await (await builder.resolve(
                NamedTypeAnnotationCode(name: superclass.identifier)))
            .isExactly(fromJsonData.objectType)) {
      var superclassDeclaration = await builder.typeDeclarationOf(superclass.identifier);
      var superclassConstructors = await builder.constructorsOf(superclassDeclaration);
      for (var constructor in superclassConstructors) {
        if (constructor.identifier.name == 'fromJson') {
          // TODO: Validate this is a valid fromJson constructor.
          superclassHasFromJson = true;
          break;
        }
      }
      if (!superclassHasFromJson) {
        throw UnsupportedError(
          'Serialization of classes that extend other classes is only '
          'supported if those classes have a valid '
          '`fromJson(Map<String, Object?> json)` constructor.');
      }
    }

    var fields = await builder.fieldsOf(clazz);
    var jsonParam = constructor.positionalParameters.single.identifier;
    builder.augment(initializers: [
      for (var field in fields)
        RawCode.fromParts([
          field.identifier,
          ' = ',
          await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              '["${field.identifier.name}"]',
            ]),
            builder,
            fromJsonData),
        ]),
      if (superclassHasFromJson)
        RawCode.fromParts([
          'super.fromJson(',
          jsonParam,
          ')',
        ]),
    ]);
  }

  Future<Code> _convertTypeFromJson(
      TypeAnnotation type,
      Code jsonReference,
      DefinitionBuilder builder,
      _FromJsonData fromJsonData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Only named types are allowed on serializable classes',
          target: type.asDiagnosticTarget),
        Severity.error));
      return RawCode.fromString('<Unable to deserialize type ${type.code}>');
    }
    var typeDecl = await builder.typeDeclarationOf(type.identifier);
    while (typeDecl is TypeAliasDeclaration) {
      var aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
          DiagnosticMessage(
            'Only named types are allowed on serializable classes, but the '
            'type alias ${type.code} resolved to a ${aliasedType.code}.',
            target: type.asDiagnosticTarget),
          Severity.error));
        return RawCode.fromString('<Unable to deserialize type ${type.code}>');
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Only class types and certain built-in types are supported for '
          'serializable classes',
          target: type.asDiagnosticTarget),
        Severity.error));
      return RawCode.fromString('<Unable to deserialize type ${type.code}>');
    }

    // The static type of the expected type, without any type arguments.
    var typeDeclType = await builder.resolve(
        NamedTypeAnnotationCode(
          name: typeDecl.identifier,
          typeArguments: [
            for (var typeParam in typeDecl.typeParameters)
              typeParam.bound?.code ?? fromJsonData.objectCode.asNullable,
          ]));
    if (await typeDeclType.isExactly(fromJsonData.listType)) {
      return RawCode.fromParts([
        '[ for (var item in ',
        jsonReference,
        ' as ',
        fromJsonData.jsonListCode,
        ') ',
        await _convertTypeFromJson(
          type.typeArguments.single,
          RawCode.fromString('item'),
          builder,
          fromJsonData),
        ']',
      ]);
    } else if (await typeDeclType.isExactly(fromJsonData.setType)) {
      return RawCode.fromParts([
        '{ for (var item in ',
        jsonReference,
        ' as ',
        fromJsonData.jsonListCode,
        ')',
        await _convertTypeFromJson(
          type.typeArguments.single,
          RawCode.fromString('item'),
          builder,
          fromJsonData),
        '}',
      ]);
    } else if (await typeDeclType.isExactly(fromJsonData.mapType)) {
      return RawCode.fromParts([
        '{ for (var entry in ',
        jsonReference,
        ' as ',
        fromJsonData.jsonMapCode,
        '.entries) entry.key: ',
        await _convertTypeFromJson(
          type.typeArguments.single,
          RawCode.fromString('entry.value'),
          builder,
          fromJsonData),
        '}',
      ]);
    }

    var constructors = await builder.constructorsOf(typeDecl);
    var fromJson = constructors
        .firstWhereOrNull((c) => c.identifier.name == 'fromJson')
        ?.identifier;
    if (fromJson != null) {
      return RawCode.fromParts([
        fromJson,
        '(',
        jsonReference,
        ' as ',
        fromJsonData.jsonMapCode,
        ')',
      ]);
    }

    // Finally, we just cast directly to the field type.
    // TODO: Check that it is a valid type we can cast to from JSON.
    return RawCode.fromParts([
      jsonReference,
      ' as ',
      type.code,
    ]);
  }
}

final class _FromJsonData {
  final NamedTypeAnnotationCode jsonListCode;
  final NamedTypeAnnotationCode jsonMapCode;
  final StaticType listType;
  final StaticType mapType;
  final NamedTypeAnnotationCode objectCode;
  final StaticType objectType;
  final StaticType setType;

  _FromJsonData({
    required this.jsonListCode,
    required this.jsonMapCode,
    required this.listType,
    required this.mapType,
    required this.objectCode,
    required this.objectType,
    required this.setType,
  });

  static Future<_FromJsonData> build(ConstructorDefinitionBuilder builder) async {
    var [list, map, object, set, string] = await Future.wait([
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'Set'),
      builder.resolveIdentifier(_dartCore, 'String'),
    ]);
    var objectCode = NamedTypeAnnotationCode(name: object);
    var nullableObjectCode = objectCode.asNullable;
    var jsonListCode = NamedTypeAnnotationCode(
        name: list,
        typeArguments: [
          nullableObjectCode,
        ]);
    var jsonMapCode = NamedTypeAnnotationCode(
        name: map,
        typeArguments: [
          NamedTypeAnnotationCode(name: string),
          nullableObjectCode,
        ]);
    var [listType, mapType, objectType, setType] = await Future.wait([
      builder.resolve(NamedTypeAnnotationCode(
        name: list, typeArguments: [nullableObjectCode])),
      builder.resolve(NamedTypeAnnotationCode(
        name: map, typeArguments: [nullableObjectCode, nullableObjectCode])),
      builder.resolve(objectCode),
      builder.resolve(NamedTypeAnnotationCode(
        name: set, typeArguments: [nullableObjectCode])),
    ]);

    return _FromJsonData(
      jsonListCode: jsonListCode,
      jsonMapCode: jsonMapCode,
      listType: listType,
      mapType: mapType,
      objectCode: objectCode,
      objectType: objectType,
      setType: setType,
    );
  }
}

/// A macro applied to a toJson instance method, which fills in the body.
macro class ToJson implements MethodDefinitionMacro {
  const ToJson();

  @override
  Future<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    // TODO: Validate we are running on a valid toJson method.

    // Gathers a bunch of type introspection data we will need later.
    var toJsonData = await _ToJsonData.build(builder);

    // TODO: support extending other classes.
    final clazz = (await builder.typeDeclarationOf(method.definingType))
        as ClassDeclaration;
    var superclass = clazz.superclass;
    var superclassHasToJson = false;
    if (superclass != null &&
        !await (await builder.resolve(
                NamedTypeAnnotationCode(name: superclass.identifier)))
            .isExactly(toJsonData.objectType)) {
      var superclassDeclaration = await builder.typeDeclarationOf(superclass.identifier);
      var superclassMethods = await builder.methodsOf(superclassDeclaration);
      for (var method in superclassMethods) {
        if (method.identifier.name == 'toJson') {
          // TODO: Validate this is a valid toJson method.
          superclassHasToJson = true;
          break;
        }
      }
      if (!superclassHasToJson) {
        throw UnsupportedError(
          'Serialization of classes that extend other classes is only '
          'supported if those classes have a valid '
          '`Map<String, Object?> toJson()` method.');
      }
    }

    var fields = await builder.fieldsOf(clazz);
    builder.augment(FunctionBodyCode.fromParts([
      ' => {',
      // TODO: Avoid the extra copying here.
      if (superclassHasToJson) '\n    ...super.toJson(),',
      for (var field in fields)
        RawCode.fromParts([
          '\n    \'',
          field.identifier.name,
          '\'',
          ': ',
          await _convertTypeToJson(
            field.type,
            RawCode.fromParts([field.identifier]),
            builder,
            toJsonData),
          ',',
        ]),
      '\n  };',
    ]));
  }

  Future<Code> _convertTypeToJson(
      TypeAnnotation type,
      Code valueReference,
      DefinitionBuilder builder,
      _ToJsonData toJsonData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Only fields with named types are allowed on serializable classes',
          target: type.asDiagnosticTarget),
        Severity.error));
      return RawCode.fromString('<Unable to serialize type ${type.code}>');
    }
    var typeDecl = await builder.typeDeclarationOf(type.identifier);
    while (typeDecl is TypeAliasDeclaration) {
      var aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
          DiagnosticMessage(
            'Only fields with named types are allowed on serializable classes',
            target: type.asDiagnosticTarget),
          Severity.error));
        return RawCode.fromString('<Unable to serialize type ${type.code}>');
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
        DiagnosticMessage(
          'Only classes are supported as field types for serializable classes',
          target: type.asDiagnosticTarget),
        Severity.error));
      return RawCode.fromString('<Unable to serialize type ${type.code}>');
    }

    var typeDeclType = await builder.resolve(
        NamedTypeAnnotationCode(
          name: typeDecl.identifier,
          typeArguments: [
            for (var typeParam in typeDecl.typeParameters)
              typeParam.bound?.code ?? toJsonData.objectCode.asNullable,
          ]));
    // If it is a List/Set type, serialize it as a JSON list.
    if (await typeDeclType.isExactly(toJsonData.listType) ||
        await typeDeclType.isExactly(toJsonData.setType)) {
      return RawCode.fromParts([
        '[ for (var item in ',
        valueReference,
        ') ',
        await _convertTypeToJson(
          type.typeArguments.single,
          RawCode.fromString('item'),
          builder,
          toJsonData),
        ']',
      ]);
    // If it is a Map type, serialize it as a JSON map.
    } else if (await typeDeclType.isExactly(toJsonData.mapType)) {
      return RawCode.fromParts([
        '{ for (var entry in ',
        valueReference,
        '.entries) entry.key: ',
        await _convertTypeToJson(
          type.typeArguments.single,
          RawCode.fromString('entry.value'),
          builder,
          toJsonData),
        '}',
      ]);
    }

    // Next, check if it has a `toJson()` method and call that.
    var methods = await builder.methodsOf(typeDecl);
    var toJson = methods
        .firstWhereOrNull((c) => c.identifier.name == 'toJson')
        ?.identifier;
    if (toJson != null) {
      return RawCode.fromParts([
        valueReference,
        '.toJson()',
      ]);
    }

    // Finally, we just return the value as is if we can't otherwise handle it.
    // TODO: Check that it is a valid type we can serialize.
    return valueReference;
  }
}


final class _ToJsonData {
  final StaticType listType;
  final StaticType mapType;
  final NamedTypeAnnotationCode objectCode;
  final StaticType objectType;
  final StaticType setType;

  _ToJsonData({
    required this.listType,
    required this.mapType,
    required this.objectCode,
    required this.objectType,
    required this.setType,
  });

  static Future<_ToJsonData> build(FunctionDefinitionBuilder builder) async {
    var [list, map, object, set] = await Future.wait([
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'Set'),
    ]);
    var objectCode = NamedTypeAnnotationCode(name: object);
    var nullableObjectCode = objectCode.asNullable;
    var [listType, mapType, objectType, setType] = await Future.wait([
      builder.resolve(NamedTypeAnnotationCode(
        name: list, typeArguments: [nullableObjectCode])),
      builder.resolve(NamedTypeAnnotationCode(
        name: map, typeArguments: [nullableObjectCode, nullableObjectCode])),
      builder.resolve(objectCode),
      builder.resolve(NamedTypeAnnotationCode(
        name: set, typeArguments: [nullableObjectCode])),
    ]);

    return _ToJsonData(
      listType: listType,
      mapType: mapType,
      objectCode: objectCode,
      objectType: objectType,
      setType: setType,
    );
  }
}

final _dartCore = Uri.parse('dart:core');

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) compare) {
    for (var item in this) {
      if (compare(item)) return item;
    }
    return null;
  }
}
