// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedOptions=--enable-experiment=macros
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package

// There is no public API exposed yet, the in-progress API lives here.
import 'package:macros/macros.dart';

final _dartCore = Uri.parse('dart:core');

/// A macro applied to a fromJson constructor, which fills in the initializer list.
/*macro*/ class FromJson implements ConstructorDefinitionMacro {
  const FromJson();

  @override
  Future<void> buildDefinitionForConstructor(ConstructorDeclaration constructor,
      ConstructorDefinitionBuilder builder) async {
    var fromJsonData = await _FromJsonData.build(builder);
    await _checkValidFromJson(constructor, fromJsonData, builder);

    var clazz = (await builder.typeDeclarationOf(constructor.definingType))
        as ClassDeclaration;
    var superclass = clazz.superclass;
    var superclassHasFromJson = false;
    if (superclass != null &&
        !await (await builder
                .resolve(NamedTypeAnnotationCode(name: superclass.identifier)))
            .isExactly(fromJsonData.objectType)) {
      var superclassDeclaration =
          await builder.typeDeclarationOf(superclass.identifier);
      var superclassConstructors =
          await builder.constructorsOf(superclassDeclaration);
      for (var superConstructor in superclassConstructors) {
        if (superConstructor.identifier.name == 'fromJson') {
          await _checkValidFromJson(superConstructor, fromJsonData, builder);
          superclassHasFromJson = true;
          break;
        }
      }
      if (!superclassHasFromJson) {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                'Serialization of classes that extend other classes is only '
                'supported if those classes have a valid '
                '`fromJson(Map<String, Object?> json)` constructor.',
                target: superclass.asDiagnosticTarget),
            Severity.error));
      }
    }

    var fields = await builder.fieldsOf(clazz);
    var jsonParam = constructor.positionalParameters.single.identifier;
    var initializers = <Code>[];
    for (var field in fields) {
      var config = await field.readConfig(builder);
      var defaultValue = config.defaultValue;
      initializers.add(RawCode.fromParts([
        field.identifier,
        ' = ',
        if (defaultValue != null) ...[
          jsonParam,
          '.containsKey(',
          config.key,
          ') ? ',
        ],
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              '[',
              config.key,
              ']',
            ]),
            builder,
            fromJsonData),
        if (defaultValue != null) ...[
          ' : ',
          defaultValue,
        ],
      ]));
    }

    if (superclassHasFromJson) {
      initializers.add(RawCode.fromParts([
        'super.fromJson(',
        jsonParam,
        ')',
      ]));
    }

    builder.augment(initializers: initializers);
  }

  Future<void> _checkValidFromJson(ConstructorDeclaration constructor,
      _FromJsonData fromJsonData, DefinitionBuilder builder) async {
    if (constructor.namedParameters.isNotEmpty ||
        constructor.positionalParameters.length != 1 ||
        !(await (await builder
                .resolve(constructor.positionalParameters.single.type.code))
            .isExactly(fromJsonData.jsonMapType))) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Expected exactly one parameter, with the type Map<String, Object?>',
              target: constructor.asDiagnosticTarget),
          Severity.error));
    }
  }

  Future<Code> _convertTypeFromJson(TypeAnnotation type, Code jsonReference,
      DefinitionBuilder builder, _FromJsonData fromJsonData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return RawCode.fromString(
          '<Unable to deserialize type ${type.code.debugString}>');
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
        return RawCode.fromString(
            '<Unable to deserialize type ${type.code.debugString}>');
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
      return RawCode.fromString(
          '<Unable to deserialize type ${type.code.debugString}>');
    }

    // The static type of the expected type, without any type arguments.
    var typeDeclType = await builder.resolve(
        NamedTypeAnnotationCode(name: typeDecl.identifier, typeArguments: [
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
        await _convertTypeFromJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, fromJsonData),
        ']',
      ]);
    } else if (await typeDeclType.isExactly(fromJsonData.setType)) {
      return RawCode.fromParts([
        '{ for (var item in ',
        jsonReference,
        ' as ',
        fromJsonData.jsonListCode,
        ')',
        await _convertTypeFromJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, fromJsonData),
        '}',
      ]);
    } else if (await typeDeclType.isExactly(fromJsonData.mapType)) {
      return RawCode.fromParts([
        '{ for (var entry in ',
        jsonReference,
        ' as ',
        fromJsonData.jsonMapCode,
        '.entries) entry.key: ',
        await _convertTypeFromJson(type.typeArguments.single,
            RawCode.fromString('entry.value'), builder, fromJsonData),
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
    // TODO(scheglov): Check that it is a valid type we can cast to from JSON.
    return RawCode.fromParts([
      jsonReference,
      ' as ',
      type.code,
    ]);
  }
}

/*macro*/ class JsonSerializable implements ClassDeclarationsMacro {
  const JsonSerializable();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    // Error if there is an existing `fromJson` constructor.
    var constructors = await builder.constructorsOf(clazz);
    var fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJson != null) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a fromJson constructor due to this existing one.',
              target: fromJson.asDiagnosticTarget),
          Severity.error));
    }

    // Error if there is an existing `toJson` method.
    var methods = await builder.methodsOf(clazz);
    var toJson = methods.firstWhereOrNull((m) => m.identifier.name == 'toJson');
    if (toJson != null) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a toJson method due to this existing one.',
              target: toJson.asDiagnosticTarget),
          Severity.error));
    }

    var map = await builder.resolveIdentifier(_dartCore, 'Map');
    var string = NamedTypeAnnotationCode(
        name: await builder.resolveIdentifier(_dartCore, 'String'));
    var object = NamedTypeAnnotationCode(
        name: await builder.resolveIdentifier(_dartCore, 'Object'));
    var mapStringObject = NamedTypeAnnotationCode(
        name: map, typeArguments: [string, object.asNullable]);

    var jsonSerializableUri = clazz.jsonSerializableUri;

    builder.declareInType(DeclarationCode.fromParts([
      '  @',
      await builder.resolveIdentifier(jsonSerializableUri, 'FromJson'),
      // TODO(scheglov): Remove/replace 'external'?
      '()\n  external ',
      clazz.identifier.name,
      '.fromJson(',
      mapStringObject,
      ' json);',
    ]));

    builder.declareInType(DeclarationCode.fromParts([
      '  @',
      await builder.resolveIdentifier(jsonSerializableUri, 'ToJson'),
      // TODO(scheglov): Remove/replace 'external'?
      '()\n  external ',
      mapStringObject,
      ' toJson();',
    ]));
  }
}

/// A macro applied to a toJson instance method, which fills in the body.
/*macro*/ class ToJson implements MethodDefinitionMacro {
  const ToJson();

  @override
  Future<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    // Gathers a bunch of type introspection data we will need later.
    var toJsonData = await _ToJsonData.build(builder);
    if (!(await _checkValidToJson(method, toJsonData, builder))) return;

    // TODO(scheglov): support extending other classes.
    var clazz = (await builder.typeDeclarationOf(method.definingType))
        as ClassDeclaration;
    var superclass = clazz.superclass;
    var superclassHasToJson = false;
    if (superclass != null &&
        !await (await builder
                .resolve(NamedTypeAnnotationCode(name: superclass.identifier)))
            .isExactly(toJsonData.objectType)) {
      var superclassDeclaration =
          await builder.typeDeclarationOf(superclass.identifier);
      var superclassMethods = await builder.methodsOf(superclassDeclaration);
      for (var superMethod in superclassMethods) {
        if (superMethod.identifier.name == 'toJson') {
          if (!(await _checkValidToJson(superMethod, toJsonData, builder))) {
            return;
          }
          superclassHasToJson = true;
          break;
        }
      }
      if (!superclassHasToJson) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'Serialization of classes that extend other classes is only '
                'supported if those classes have a valid '
                '`Map<String, Object?> toJson()` method.',
                target: superclass.asDiagnosticTarget),
            Severity.error));
        return;
      }
    }

    var fields = await builder.fieldsOf(clazz);
    var parts = <Object>[
      '{\n    var json = ',
      if (superclassHasToJson)
        'super.toJson()'
      else ...[
        '<',
        toJsonData.stringCode,
        ', ',
        toJsonData.objectCode.asNullable,
        '>{}',
      ],
      ';\n    '
    ];
    for (var field in fields) {
      var config = await field.readConfig(builder);
      var doNullCheck = !config.includeIfNull && field.type.isNullable;
      if (doNullCheck) {
        // TODO(scheglov): Compare == `null` instead, once we can resolve `null`.
        parts.addAll([
          'if (',
          field.identifier,
          ' is! ',
          toJsonData.nullIdentifier,
          ') {\n      ',
        ]);
      }
      parts.addAll([
        'json[',
        config.key,
        '] = ',
        await _convertTypeToJson(field.type,
            RawCode.fromParts([field.identifier]), builder, toJsonData),
        ';\n',
      ]);
      if (doNullCheck) {
        parts.add('    }\n');
      }
    }
    parts.add('    return json;\n  }');

    builder.augment(FunctionBodyCode.fromParts(parts));
  }

  Future<bool> _checkValidToJson(MethodDeclaration method,
      _ToJsonData toJsonData, DefinitionBuilder builder) async {
    if (method.namedParameters.isNotEmpty ||
        method.positionalParameters.isNotEmpty ||
        !(await (await builder.resolve(method.returnType.code))
            .isExactly(toJsonData.jsonMapType))) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Expected no parameters, and a return type of Map<String, Object?>',
              target: method.asDiagnosticTarget),
          Severity.error));
      return false;
    }
    return true;
  }

  Future<Code> _convertTypeToJson(TypeAnnotation type, Code valueReference,
      DefinitionBuilder builder, _ToJsonData toJsonData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return RawCode.fromString(
          '<Unable to serialize type ${type.code.debugString}>');
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
        return RawCode.fromString(
            '<Unable to serialize type ${type.code.debugString}>');
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only classes are supported as field types for serializable classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return RawCode.fromString(
          '<Unable to serialize type ${type.code.debugString}>');
    }

    var typeDeclType = await builder.resolve(
        NamedTypeAnnotationCode(name: typeDecl.identifier, typeArguments: [
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
        await _convertTypeToJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, toJsonData),
        ']',
      ]);
      // If it is a Map type, serialize it as a JSON map.
    } else if (await typeDeclType.isExactly(toJsonData.mapType)) {
      return RawCode.fromParts([
        '{ for (var entry in ',
        valueReference,
        '.entries) entry.key: ',
        await _convertTypeToJson(type.typeArguments.single,
            RawCode.fromString('entry.value'), builder, toJsonData),
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
    // TODO(scheglov): Check that it is a valid type we can serialize.
    return valueReference;
  }
}

final class _FieldConfig {
  final Code? defaultValue;

  final Code key;

  final bool includeIfNull;

  factory _FieldConfig(
      FieldDeclaration field, ConstructorMetadataAnnotation? jsonKey) {
    bool? includeIfNull;
    var includeIfNullArg = jsonKey?.namedArguments['includeIfNull'];
    if (includeIfNullArg != null) {
      if (!field.type.isNullable) {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                '`includeIfNull` cannot be used for non-nullable fields',
                target: jsonKey!.asDiagnosticTarget),
            Severity.error));
      }
      // TODO(scheglov): Use constant eval to do this better.
      var argString = includeIfNullArg.debugString;
      includeIfNull = switch (argString) {
        'false' => false,
        'true' => true,
        _ => throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                'Only `true` or `false` literals are allowed for '
                '`includeIfNull` arguments.',
                target: jsonKey!.asDiagnosticTarget),
            Severity.error)),
      };
    }

    return _FieldConfig._(
      defaultValue: jsonKey?.namedArguments['defaultValue'],
      includeIfNull: includeIfNull ?? false,
      key: jsonKey?.namedArguments['name'] ??
          RawCode.fromString('\'${field.identifier.name}\''),
    );
  }

  _FieldConfig._({
    required this.defaultValue,
    required this.includeIfNull,
    required this.key,
  });
}

final class _FromJsonData {
  final NamedTypeAnnotationCode jsonListCode;
  final NamedTypeAnnotationCode jsonMapCode;
  final StaticType jsonMapType;
  final StaticType listType;
  final StaticType mapType;
  final NamedTypeAnnotationCode objectCode;
  final StaticType objectType;
  final StaticType setType;

  _FromJsonData({
    required this.jsonListCode,
    required this.jsonMapCode,
    required this.jsonMapType,
    required this.listType,
    required this.mapType,
    required this.objectCode,
    required this.objectType,
    required this.setType,
  });

  static Future<_FromJsonData> build(
      ConstructorDefinitionBuilder builder) async {
    var [list, map, object, set, string] = await Future.wait([
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'Set'),
      builder.resolveIdentifier(_dartCore, 'String'),
    ]);
    var objectCode = NamedTypeAnnotationCode(name: object);
    var nullableObjectCode = objectCode.asNullable;
    var jsonListCode = NamedTypeAnnotationCode(name: list, typeArguments: [
      nullableObjectCode,
    ]);
    var jsonMapCode = NamedTypeAnnotationCode(name: map, typeArguments: [
      NamedTypeAnnotationCode(name: string),
      nullableObjectCode,
    ]);
    var [jsonMapType, listType, mapType, objectType, setType] =
        await Future.wait([
      builder.resolve(jsonMapCode),
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
      jsonMapType: jsonMapType,
      listType: listType,
      mapType: mapType,
      objectCode: objectCode,
      objectType: objectType,
      setType: setType,
    );
  }
}

final class _ToJsonData {
  final StaticType jsonMapType;
  final StaticType listType;
  final StaticType mapType;
  final Identifier nullIdentifier;
  final NamedTypeAnnotationCode objectCode;
  final StaticType objectType;
  final StaticType setType;
  final NamedTypeAnnotationCode stringCode;

  _ToJsonData({
    required this.jsonMapType,
    required this.listType,
    required this.mapType,
    required this.nullIdentifier,
    required this.objectCode,
    required this.objectType,
    required this.setType,
    required this.stringCode,
  });

  static Future<_ToJsonData> build(FunctionDefinitionBuilder builder) async {
    var [list, map, nullIdentifier, object, set, string] = await Future.wait([
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'Null'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'Set'),
      builder.resolveIdentifier(_dartCore, 'String'),
    ]);
    var objectCode = NamedTypeAnnotationCode(name: object);
    var stringCode = NamedTypeAnnotationCode(name: string);
    var nullableObjectCode = objectCode.asNullable;
    var [jsonMapType, listType, mapType, objectType, setType] =
        await Future.wait([
      builder.resolve(NamedTypeAnnotationCode(name: map, typeArguments: [
        stringCode,
        nullableObjectCode,
      ])),
      builder.resolve(NamedTypeAnnotationCode(
          name: list, typeArguments: [nullableObjectCode])),
      builder.resolve(NamedTypeAnnotationCode(
          name: map, typeArguments: [nullableObjectCode, nullableObjectCode])),
      builder.resolve(objectCode),
      builder.resolve(NamedTypeAnnotationCode(
          name: set, typeArguments: [nullableObjectCode])),
    ]);

    return _ToJsonData(
      jsonMapType: jsonMapType,
      listType: listType,
      mapType: mapType,
      nullIdentifier: nullIdentifier,
      objectCode: objectCode,
      objectType: objectType,
      setType: setType,
      stringCode: stringCode,
    );
  }
}

extension on FieldDeclaration {
  /// Returns the configuration data for this field, reading it from the
  /// `JsonKey` annotation if present, and otherwise using defaults.
  Future<_FieldConfig> readConfig(DefinitionBuilder builder) async {
    ConstructorMetadataAnnotation? jsonKey;
    for (var annotation in metadata) {
      if (annotation is! ConstructorMetadataAnnotation) continue;
      if (annotation.type.identifier.name != 'JsonKey') continue;
      var declaration =
          await builder.typeDeclarationOf(annotation.type.identifier);
      if (declaration.library.uri != jsonKeyUri) continue;

      if (jsonKey != null) {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage('Only one JsonKey annotation is allowed.',
                target: annotation.asDiagnosticTarget),
            Severity.error));
      } else {
        jsonKey = annotation;
      }
    }
    return _FieldConfig(this, jsonKey);
  }
}

extension on Code {
  String get debugString {
    var buffer = StringBuffer();
    _writeDebugString(buffer);
    return buffer.toString();
  }

  void _writeDebugString(StringBuffer buffer) {
    for (var part in parts) {
      switch (part) {
        case Code():
          part._writeDebugString(buffer);
        case Identifier():
          buffer.write(part.name);
        default:
          buffer.write(part);
      }
    }
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) compare) {
    for (var item in this) {
      if (compare(item)) return item;
    }
    return null;
  }
}

// TODO(scheglov): These only work because the macro file lives right next to the file
// it is applied to, we need a better solution at some point.
extension _RelativeUris on Declaration {
  Uri get jsonKeyUri => library.uri.resolve('json_key.dart');

  Uri get jsonSerializableUri => library.uri.resolve('json_serializable.dart');
}
