// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:macros/macros.dart';

/// A macro which adds a `fromJson(Map<String, Object?> json)` constructor and
/// a `Map<String, Object?> toJson()` method to a class.
///
/// To use this macro, annotate your class with `@JsonCodable()` and enable the
/// macros experiment (see README.md for full instructions).
///
/// The implementations are derived from the fields defined directly on the
/// annotated class, and field names are expected to exactly match the keys of
/// the maps that they are being decoded from.
///
/// If extending any class other than [Object], then the super class is expected
/// to also have a corresponding `toJson` method and `fromJson` constructor.
///
/// Annotated classes are not allowed to have a manually defined `toJson` method
/// or `fromJson` constructor.
macro class JsonCodable
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonCodable();

  /// Declares the `fromJson` constructor and `toJson` method, but does not
  /// implement them.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    if (clazz.typeParameters.isNotEmpty) {
      throw DiagnosticException(Diagnostic(DiagnosticMessage(
              // TODO: Target the actual type parameter, issue #55611
              'Cannot be applied to classes with generic type parameters'),
          Severity.error));
    }

    final (map, string, object, _, _) = await (
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'String'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      // These are just for validation, and will throw if the check fails.
      _checkNoFromJson(builder, clazz),
      _checkNoToJson(builder, clazz),
    ).wait;
    final mapStringObject = NamedTypeAnnotationCode(name: map, typeArguments: [
      NamedTypeAnnotationCode(name: string),
      NamedTypeAnnotationCode(name: object).asNullable
    ]);

    builder.declareInType(DeclarationCode.fromParts([
      // TODO(language#3580): Remove/replace 'external'?
      '  external ',
      clazz.identifier.name,
      '.fromJson(',
      mapStringObject,
      ' json);',
    ]));

    builder.declareInType(DeclarationCode.fromParts([
      // TODO(language#3580): Remove/replace 'external'?
      '  external ',
      mapStringObject,
      ' toJson();',
    ]));
  }

  /// Provides the actual definitions of the `fromJson` constructor and `toJson`
  /// method, which were declared in the previous phase.
  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final (introspectionData, constructors, methods) = await (
      _SharedIntrospectionData.build(builder, clazz),
      builder.constructorsOf(clazz),
      builder.methodsOf(clazz)
    ).wait;
    final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    final toJson =
        methods.firstWhereOrNull((c) => c.identifier.name == 'toJson');

    // An earlier step failed, just bail out without emitting additional
    // diagnostics.
    if (fromJson == null || toJson == null) return;

    final (fromJsonBuilder, toJsonBuilder) = await (
      builder.buildConstructor(fromJson.identifier),
      builder.buildMethod(toJson.identifier),
    ).wait;
    await (
      _buildFromJson(fromJson, fromJsonBuilder, introspectionData),
      _buildToJson(toJson, toJsonBuilder, introspectionData),
    ).wait;
  }

  /// Builds the actual `fromJson` constructor.
  Future<void> _buildFromJson(
      ConstructorDeclaration constructor,
      ConstructorDefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    await _checkValidFromJson(constructor, introspectionData, builder);

    // If extending something other than `Object`, it must have a `fromJson`
    // constructor.
    var superclassHasFromJson = false;
    final superclassDeclaration = introspectionData.superclass;
    if (superclassDeclaration != null &&
        !superclassDeclaration.isExactly('Object', _dartCore)) {
      final superclassConstructors =
          await builder.constructorsOf(superclassDeclaration);
      for (final superConstructor in superclassConstructors) {
        if (superConstructor.identifier.name == 'fromJson') {
          await _checkValidFromJson(
              superConstructor, introspectionData, builder);
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
                target: introspectionData.clazz.superclass?.asDiagnosticTarget),
            Severity.error));
      }
    }

    final fields = introspectionData.fields;
    final jsonParam = constructor.positionalParameters.single.identifier;

    Future<Code> initializerForField(FieldDeclaration field) async {
      return RawCode.fromParts([
        field.identifier,
        ' = ',
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              "['",
              field.identifier.name,
              "']",
            ]),
            builder,
            introspectionData),
      ]);
    }

    final initializers = await Future.wait(fields.map(initializerForField));

    if (superclassHasFromJson) {
      initializers.add(RawCode.fromParts([
        'super.fromJson(',
        jsonParam,
        ')',
      ]));
    }

    builder.augment(initializers: initializers);
  }

  /// Builds the actual `toJson` method.
  Future<void> _buildToJson(
      MethodDeclaration method,
      FunctionDefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    if (!(await _checkValidToJson(method, introspectionData, builder))) return;

    // If extending something other than `Object`, it must have a `toJson`
    // method.
    var superclassHasToJson = false;
    final superclassDeclaration = introspectionData.superclass;
    if (superclassDeclaration != null &&
        !superclassDeclaration.isExactly('Object', _dartCore)) {
      final superclassMethods = await builder.methodsOf(superclassDeclaration);
      for (final superMethod in superclassMethods) {
        if (superMethod.identifier.name == 'toJson') {
          if (!(await _checkValidToJson(
              superMethod, introspectionData, builder))) {
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
                target: introspectionData.clazz.superclass?.asDiagnosticTarget),
            Severity.error));
        return;
      }
    }

    final fields = introspectionData.fields;
    final parts = <Object>[
      '{\n    final json = ',
      if (superclassHasToJson)
        'super.toJson()'
      else ...[
        '<',
        introspectionData.stringCode,
        ', ',
        introspectionData.objectCode.asNullable,
        '>{}',
      ],
      ';\n    ',
    ];

    Future<Code> addEntryForField(FieldDeclaration field) async {
      final parts = <Object>[];
      final doNullCheck = field.type.isNullable;
      if (doNullCheck) {
        parts.addAll([
          'if (',
          field.identifier,
          // `null` is a reserved word, we can just use it.
          ' != null) {\n      ',
        ]);
      }
      parts.addAll([
        "json['",
        field.identifier.name,
        "'] = ",
        await _convertTypeToJson(
            field.type,
            RawCode.fromParts([
              field.identifier,
              if (doNullCheck) '!',
            ]),
            builder,
            introspectionData),
        ';\n    ',
      ]);
      if (doNullCheck) {
        parts.add('}\n    ');
      }
      return RawCode.fromParts(parts);
    }

    parts.addAll(await Future.wait(fields.map(addEntryForField)));

    parts.add('return json;\n  }');

    builder.augment(FunctionBodyCode.fromParts(parts));
  }

  /// Throws a [DiagnosticException] if there is an existing `fromJson`
  /// constructor on [clazz].
  Future<void> _checkNoFromJson(
      DeclarationBuilder builder, ClassDeclaration clazz) async {
    final constructors = await builder.constructorsOf(clazz);
    final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJson != null) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a fromJson constructor due to this existing '
              'one.',
              target: fromJson.asDiagnosticTarget),
          Severity.error));
    }
  }

  /// Throws a [DiagnosticException] if there is an existing `toJson` method on
  /// [clazz].
  Future<void> _checkNoToJson(
      DeclarationBuilder builder, ClassDeclaration clazz) async {
    final methods = await builder.methodsOf(clazz);
    final toJson =
        methods.firstWhereOrNull((m) => m.identifier.name == 'toJson');
    if (toJson != null) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a toJson method due to this existing one.',
              target: toJson.asDiagnosticTarget),
          Severity.error));
    }
  }

  /// Checks that [constructor] is a valid `fromJson` constructor, and throws a
  /// [DiagnosticException] if not.
  Future<void> _checkValidFromJson(
      ConstructorDeclaration constructor,
      _SharedIntrospectionData introspectionData,
      DefinitionBuilder builder) async {
    if (constructor.namedParameters.isNotEmpty ||
        constructor.positionalParameters.length != 1 ||
        !(await (await builder
                .resolve(constructor.positionalParameters.single.type.code))
            .isExactly(introspectionData.jsonMapType))) {
      throw DiagnosticException(Diagnostic(
          DiagnosticMessage(
              'Expected exactly one parameter, with the type '
              'Map<String, Object?>',
              target: constructor.asDiagnosticTarget),
          Severity.error));
    }
  }

  /// Returns a [Code] object which is an expression that converts a JSON map
  /// (referenced by [jsonReference]) into an instance of type [type].
  Future<Code> _convertTypeFromJson(
      TypeAnnotation type,
      Code jsonReference,
      DefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable '
              'classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return RawCode.fromString(
          "throw 'Unable to deserialize type ${type.code.debugString}'");
    }

    // Follow type aliases until we reach an actual named type.
    var classDecl = await _classDeclarationOf(builder, type);
    if (classDecl == null) {
      return RawCode.fromString(
          "throw 'Unable to deserialize type ${type.code.debugString}'");
    }

    var nullCheck = type.isNullable
        ? RawCode.fromParts([
            jsonReference,
            // `null` is a reserved word, we can just use it.
            ' == null ? null : ',
          ])
        : null;

    // Check if `typeDecl` is one of the supported collection types.
    if (classDecl.isExactly('List', _dartCore)) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        '[ for (final item in ',
        jsonReference,
        ' as ',
        introspectionData.jsonListCode,
        ') ',
        await _convertTypeFromJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, introspectionData),
        ']',
      ]);
    } else if (classDecl.isExactly('Set', _dartCore)) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        '{ for (final item in ',
        jsonReference,
        ' as ',
        introspectionData.jsonListCode,
        ')',
        await _convertTypeFromJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, introspectionData),
        '}',
      ]);
    } else if (classDecl.isExactly('Map', _dartCore)) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        '{ for (final ',
        introspectionData.mapEntry,
        '(:key, :value) in (',
        jsonReference,
        ' as ',
        introspectionData.jsonMapCode,
        ').entries) key: ',
        await _convertTypeFromJson(type.typeArguments.last,
            RawCode.fromString('value'), builder, introspectionData),
        '}',
      ]);
    }

    // Otherwise, check if `classDecl` has a `fromJson` constructor.
    final constructors = await builder.constructorsOf(classDecl);
    final fromJson = constructors
        .firstWhereOrNull((c) => c.identifier.name == 'fromJson')
        ?.identifier;
    if (fromJson != null) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        fromJson,
        '(',
        jsonReference,
        ' as ',
        introspectionData.jsonMapCode,
        ')',
      ]);
    }

    // Finally, we just cast directly to the field type.
    // TODO: Check that it is a valid type we can cast from JSON.
    return RawCode.fromParts([
      jsonReference,
      ' as ',
      type.code,
    ]);
  }

  /// Checks that [method] is a valid `toJson` method, and throws a
  /// [DiagnosticException] if not.
  Future<bool> _checkValidToJson(
      MethodDeclaration method,
      _SharedIntrospectionData introspectionData,
      DefinitionBuilder builder) async {
    if (method.namedParameters.isNotEmpty ||
        method.positionalParameters.isNotEmpty ||
        !(await (await builder.resolve(method.returnType.code))
            .isExactly(introspectionData.jsonMapType))) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Expected no parameters, and a return type of '
              'Map<String, Object?>',
              target: method.asDiagnosticTarget),
          Severity.error));
      return false;
    }
    return true;
  }

  /// Returns a [Code] object which is an expression that converts an instance
  /// of type [type] (referenced by [valueReference]) into a JSON map.
  Future<Code> _convertTypeToJson(
      TypeAnnotation type,
      Code valueReference,
      DefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    if (type is! NamedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable '
              'classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return RawCode.fromString(
          "throw 'Unable to serialize type ${type.code.debugString}'");
    }

    // Follow type aliases until we reach an actual named type.
    var classDecl = await _classDeclarationOf(builder, type);
    if (classDecl == null) {
      return RawCode.fromString(
          "throw 'Unable to serialize type ${type.code.debugString}'");
    }

    var nullCheck = type.isNullable
        ? RawCode.fromParts([
            valueReference,
            // `null` is a reserved word, we can just use it.
            ' == null ? null : ',
          ])
        : null;

    // Check for the supported collection types, and serialize them accordingly.
    if (classDecl.isExactly('List', _dartCore) ||
        classDecl.isExactly('Set', _dartCore)) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        '[ for (final item in ',
        valueReference,
        ') ',
        await _convertTypeToJson(type.typeArguments.single,
            RawCode.fromString('item'), builder, introspectionData),
        ']',
      ]);
    } else if (classDecl.isExactly('Map', _dartCore)) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        '{ for (final ', introspectionData.mapEntry,
        '(:key, :value) in ',
        valueReference,
        '.entries) key: ',
        await _convertTypeToJson(type.typeArguments.last,
            RawCode.fromString('value'), builder, introspectionData),
        '}',
      ]);
    }

    // Next, check if it has a `toJson()` method and call that.
    final methods = await builder.methodsOf(classDecl);
    final toJson = methods
        .firstWhereOrNull((c) => c.identifier.name == 'toJson')
        ?.identifier;
    if (toJson != null) {
      return RawCode.fromParts([
        if (nullCheck != null) nullCheck,
        valueReference,
        '.toJson()',
      ]);
    }

    // Finally, we just return the value as is if we can't otherwise handle it.
    // TODO: Check that it is a valid type we can serialize.
    return valueReference;
  }

  /// Follows [type] through any type aliases, until it reaches a
  /// [ClassDeclaration], or returns null if it does not bottom out on a class.
  Future<ClassDeclaration?> _classDeclarationOf(
      DefinitionBuilder builder, NamedTypeAnnotation type) async {
    var typeDecl = await builder.typeDeclarationOf(type.identifier);
    while (typeDecl is TypeAliasDeclaration) {
      final aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'Only fields with named types are allowed on serializable '
                'classes',
                target: type.asDiagnosticTarget),
            Severity.error));
        return null;
      }
      typeDecl = await builder.typeDeclarationOf(aliasedType.identifier);
    }
    if (typeDecl is! ClassDeclaration) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only classes are supported as field types for serializable '
              'classes',
              target: type.asDiagnosticTarget),
          Severity.error));
      return null;
    }
    return typeDecl;
  }
}

/// This data is collected asynchronously, so we only want to do it once and
/// share that work across multiple locations.
final class _SharedIntrospectionData {
  /// The declaration of the class we are generating for.
  final ClassDeclaration clazz;

  /// All the fields on the [clazz].
  final List<FieldDeclaration> fields;

  /// A [Code] representation of the type [List<Object?>].
  final NamedTypeAnnotationCode jsonListCode;

  /// A [Code] representation of the type [Map<String, Object?>].
  final NamedTypeAnnotationCode jsonMapCode;

  /// The resolved [StaticType] representing the [Map<String, Object?>] type.
  final StaticType jsonMapType;

  /// The resolved identifier for the [MapEntry] class.
  final Identifier mapEntry;

  /// A [Code] representation of the type [Object].
  final NamedTypeAnnotationCode objectCode;

  /// A [Code] representation of the type [String].
  final NamedTypeAnnotationCode stringCode;

  /// The declaration of the superclass of [clazz], if it is not [Object].
  final ClassDeclaration? superclass;

  _SharedIntrospectionData({
    required this.clazz,
    required this.fields,
    required this.jsonListCode,
    required this.jsonMapCode,
    required this.jsonMapType,
    required this.mapEntry,
    required this.objectCode,
    required this.stringCode,
    required this.superclass,
  });

  static Future<_SharedIntrospectionData> build(
      DeclarationPhaseIntrospector builder, ClassDeclaration clazz) async {
    final (list, map, mapEntry, object, string) = await (
      builder.resolveIdentifier(_dartCore, 'List'),
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'MapEntry'),
      builder.resolveIdentifier(_dartCore, 'Object'),
      builder.resolveIdentifier(_dartCore, 'String'),
    ).wait;
    final objectCode = NamedTypeAnnotationCode(name: object);
    final nullableObjectCode = objectCode.asNullable;
    final jsonListCode = NamedTypeAnnotationCode(name: list, typeArguments: [
      nullableObjectCode,
    ]);
    final jsonMapCode = NamedTypeAnnotationCode(name: map, typeArguments: [
      NamedTypeAnnotationCode(name: string),
      nullableObjectCode,
    ]);
    final stringCode = NamedTypeAnnotationCode(name: string);
    final superclass = clazz.superclass;
    final (fields, jsonMapType, superclassDecl) = await (
      builder.fieldsOf(clazz),
      builder.resolve(jsonMapCode),
      superclass == null
          ? Future.value(null)
          : builder.typeDeclarationOf(superclass.identifier),
    ).wait;

    return _SharedIntrospectionData(
      clazz: clazz,
      fields: fields,
      jsonListCode: jsonListCode,
      jsonMapCode: jsonMapCode,
      jsonMapType: jsonMapType,
      mapEntry: mapEntry,
      objectCode: objectCode,
      stringCode: stringCode,
      superclass: superclassDecl as ClassDeclaration?,
    );
  }
}

final _dartCore = Uri.parse('dart:core');

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) compare) {
    for (final item in this) {
      if (compare(item)) return item;
    }
    return null;
  }
}

extension _IsExactly on TypeDeclaration {
  /// Cheaper than checking types using a [StaticType].
  bool isExactly(String name, Uri library) =>
      identifier.name == name && this.library.uri == library;
}

extension on Code {
  /// Used for error messages.
  String get debugString {
    final buffer = StringBuffer();
    _writeDebugString(buffer);
    return buffer.toString();
  }

  void _writeDebugString(StringBuffer buffer) {
    for (final part in parts) {
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
