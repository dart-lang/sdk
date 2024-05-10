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
///
/// See also [JsonEncodable] and [JsonDecodable] if you only want either the
/// `toJson` or `fromJson` functionality.
macro class JsonCodable
    with _Shared, _FromJson, _ToJson
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonCodable();

  /// Declares the `fromJson` constructor and `toJson` method, but does not
  /// implement them.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final mapStringObject = await _setup(clazz, builder);

    await (
      _declareFromJson(clazz, builder, mapStringObject),
      _declareToJson(clazz, builder, mapStringObject),
    ).wait;
  }

  /// Provides the actual definitions of the `fromJson` constructor and `toJson`
  /// method, which were declared in the previous phase.
  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final introspectionData =
        await _SharedIntrospectionData.build(builder, clazz);

    await (
      _buildFromJson(clazz, builder, introspectionData),
      _buildToJson(clazz, builder, introspectionData),
    ).wait;
  }
}

/// A macro which adds a `Map<String, Object?> toJson()` method to a class.
///
/// To use this macro, annotate your class with `@JsonEncodable()` and enable
/// the macros experiment (see README.md for full instructions).
///
/// The implementations are derived from the fields defined directly on the
/// annotated class, and field names are expected to exactly match the keys of
/// the maps that they are being decoded from.
///
/// If extending any class other than [Object], then the super class is expected
/// to also have a corresponding `toJson` method.
///
/// Annotated classes are not allowed to have a manually defined `toJson`
/// method.
macro class JsonEncodable
    with _Shared, _ToJson
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonEncodable();

  /// Declares the `toJson` method, but does not implement it.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final mapStringObject = await _setup(clazz, builder);
    await _declareToJson(clazz, builder, mapStringObject);
  }

  /// Provides the actual definition of the `toJson` method, which was declared
  /// in the previous phase.
  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final introspectionData =
        await _SharedIntrospectionData.build(builder, clazz);
    await _buildToJson(clazz, builder, introspectionData);
  }
}

/// A macro which adds a `fromJson(Map<String, Object?> json)` constructor to a
/// class.
///
/// To use this macro, annotate your class with `@JsonDecodable()` and enable
/// the macros experiment (see README.md for full instructions).
///
/// The implementations are derived from the fields defined directly on the
/// annotated class, and field names are expected to exactly match the keys of
/// the maps that they are being decoded from.
///
/// If extending any class other than [Object], then the super class is expected
/// to also have a corresponding `fromJson` constructor.
///
/// Annotated classes are not allowed to have a manually defined `fromJson`
/// constructor.
macro class JsonDecodable
    with _Shared, _FromJson
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonDecodable();

  /// Declares the `fromJson` constructor but does not implement it.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final mapStringObject = await _setup(clazz, builder);
    await _declareFromJson(clazz, builder, mapStringObject);
  }

  /// Provides the actual definition of the `from` constructor, which was
  /// declared in the previous phase.
  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final introspectionData =
        await _SharedIntrospectionData.build(builder, clazz);
    await _buildFromJson(clazz, builder, introspectionData);
  }
}

/// Shared logic for all macros which run in the declarations phase.
mixin _Shared {
  /// Returns [type] as a [NamedTypeAnnotation] if it is one, otherwise returns
  /// `null` and emits relevant error diagnostics.
  NamedTypeAnnotation? _checkNamedType(TypeAnnotation type, Builder builder) {
    if (type is NamedTypeAnnotation) return type;
    if (type is OmittedTypeAnnotation) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with explicit types are allowed on serializable '
              'classes, please add a type.',
              target: type.asDiagnosticTarget),
          Severity.error));
    } else {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Only fields with named types are allowed on serializable '
              'classes.',
              target: type.asDiagnosticTarget),
          Severity.error));
    }
    return null;
  }

  /// Does some basic validation on [clazz], and shared setup logic.
  ///
  /// Returns a code representation of the [Map<String, Object?>] class.
  Future<NamedTypeAnnotationCode> _setup(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    if (clazz.typeParameters.isNotEmpty) {
      throw DiagnosticException(Diagnostic(DiagnosticMessage(
              // TODO: Target the actual type parameter, issue #55611
              'Cannot be applied to classes with generic type parameters'),
          Severity.error));
    }

    final (map, string, object) = await (
      builder.resolveIdentifier(_dartCore, 'Map'),
      builder.resolveIdentifier(_dartCore, 'String'),
      builder.resolveIdentifier(_dartCore, 'Object'),
    ).wait;
    return NamedTypeAnnotationCode(name: map, typeArguments: [
      NamedTypeAnnotationCode(name: string),
      NamedTypeAnnotationCode(name: object).asNullable
    ]);
  }
}

/// Shared logic for macros that want to generate a `fromJson` constructor.
mixin _FromJson on _Shared {
  /// Builds the actual `fromJson` constructor.
  Future<void> _buildFromJson(
      ClassDeclaration clazz,
      TypeDefinitionBuilder typeBuilder,
      _SharedIntrospectionData introspectionData) async {
    final constructors = await typeBuilder.constructorsOf(clazz);
    final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJson == null) return;
    await _checkValidFromJson(fromJson, introspectionData, typeBuilder);
    final builder = await typeBuilder.buildConstructor(fromJson.identifier);

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
    final jsonParam = fromJson.positionalParameters.single.identifier;

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

  /// Emits an error [Diagnostic] if there is an existing `fromJson`
  /// constructor on [clazz].
  ///
  /// Returns `true` if the check succeeded (there was no `fromJson`) and false
  /// if it didn't (a diagnostic was emitted).
  Future<bool> _checkNoFromJson(
      DeclarationBuilder builder, ClassDeclaration clazz) async {
    final constructors = await builder.constructorsOf(clazz);
    final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJson != null) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a fromJson constructor due to this existing '
              'one.',
              target: fromJson.asDiagnosticTarget),
          Severity.error));
      return false;
    }
    return true;
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
      TypeAnnotation rawType,
      Code jsonReference,
      DefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    final type = _checkNamedType(rawType, builder);
    if (type == null) {
      return RawCode.fromString(
          "throw 'Unable to deserialize type ${rawType.code.debugString}'");
    }

    // Follow type aliases until we reach an actual named type.
    var classDecl = await type.classDeclaration(builder);
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

    // Check for the supported core types, and deserialize them accordingly.
    if (classDecl.library.uri == _dartCore) {
      switch (classDecl.identifier.name) {
        case 'List':
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
        case 'Set':
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
        case 'Map':
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
        case 'int' || 'double' || 'num' || 'String' || 'bool':
          return RawCode.fromParts([
            jsonReference,
            ' as ',
            type.code,
          ]);
      }
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

    // Unsupported type, report an error and return valid code that throws.
    builder.report(Diagnostic(
        DiagnosticMessage(
            'Unable to deserialize type, it must be a native JSON type or a '
            'type with a `fromJson(Map<String, Object?> json)` constructor.',
            target: type.asDiagnosticTarget),
        Severity.error));
    return RawCode.fromString(
        "throw 'Unable to deserialize type ${type.code.debugString}'");
  }

  /// Declares a `fromJson` constructor in [clazz], if one does not exist
  /// already.
  Future<void> _declareFromJson(
      ClassDeclaration clazz,
      MemberDeclarationBuilder builder,
      NamedTypeAnnotationCode mapStringObject) async {
    if (!(await _checkNoFromJson(builder, clazz))) return;

    builder.declareInType(DeclarationCode.fromParts([
      // TODO(language#3580): Remove/replace 'external'?
      '  external ',
      clazz.identifier.name,
      '.fromJson(',
      mapStringObject,
      ' json);',
    ]));
  }
}

/// Shared logic for macros that want to generate a `toJson` method.
mixin _ToJson on _Shared {
  /// Builds the actual `toJson` method.
  Future<void> _buildToJson(
      ClassDeclaration clazz,
      TypeDefinitionBuilder typeBuilder,
      _SharedIntrospectionData introspectionData) async {
    final methods = await typeBuilder.methodsOf(clazz);
    final toJson =
        methods.firstWhereOrNull((c) => c.identifier.name == 'toJson');
    if (toJson == null) return;
    if (!(await _checkValidToJson(toJson, introspectionData, typeBuilder))) {
      return;
    }

    final builder = await typeBuilder.buildMethod(toJson.identifier);

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

  /// Emits an error [Diagnostic] if there is an existing `toJson` method on
  /// [clazz].
  ///
  /// Returns `true` if the check succeeded (there was no `toJson`) and false
  /// if it didn't (a diagnostic was emitted).
  Future<bool> _checkNoToJson(
      DeclarationBuilder builder, ClassDeclaration clazz) async {
    final methods = await builder.methodsOf(clazz);
    final toJson =
        methods.firstWhereOrNull((m) => m.identifier.name == 'toJson');
    if (toJson != null) {
      builder.report(Diagnostic(
          DiagnosticMessage(
              'Cannot generate a toJson method due to this existing one.',
              target: toJson.asDiagnosticTarget),
          Severity.error));
      return false;
    }
    return true;
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
      TypeAnnotation rawType,
      Code valueReference,
      DefinitionBuilder builder,
      _SharedIntrospectionData introspectionData) async {
    final type = _checkNamedType(rawType, builder);
    if (type == null) {
      return RawCode.fromString(
          "throw 'Unable to serialize type ${rawType.code.debugString}'");
    }

    // Follow type aliases until we reach an actual named type.
    var classDecl = await type.classDeclaration(builder);
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

    // Check for the supported core types, and serialize them accordingly.
    if (classDecl.library.uri == _dartCore) {
      switch (classDecl.identifier.name) {
        case 'List' || 'Set':
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            '[ for (final item in ',
            valueReference,
            ') ',
            await _convertTypeToJson(type.typeArguments.single,
                RawCode.fromString('item'), builder, introspectionData),
            ']',
          ]);
        case 'Map':
          return RawCode.fromParts([
            if (nullCheck != null) nullCheck,
            '{ for (final ',
            introspectionData.mapEntry,
            '(:key, :value) in ',
            valueReference,
            '.entries) key: ',
            await _convertTypeToJson(type.typeArguments.last,
                RawCode.fromString('value'), builder, introspectionData),
            '}',
          ]);
        case 'int' || 'double' || 'num' || 'String' || 'bool':
          return valueReference;
      }
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

    // Unsupported type, report an error and return valid code that throws.
    builder.report(Diagnostic(
        DiagnosticMessage(
            'Unable to serialize type, it must be a native JSON type or a '
            'type with a `Map<String, Object?> toJson()` method.',
            target: type.asDiagnosticTarget),
        Severity.error));
    return RawCode.fromString(
        "throw 'Unable to serialize type ${type.code.debugString}'");
  }

  /// Declares a `toJson` method in [clazz], if one does not exist already.
  Future<void> _declareToJson(
      ClassDeclaration clazz,
      MemberDeclarationBuilder builder,
      NamedTypeAnnotationCode mapStringObject) async {
    if (!(await _checkNoToJson(builder, clazz))) return;
    builder.declareInType(DeclarationCode.fromParts([
      // TODO(language#3580): Remove/replace 'external'?
      '  external ',
      mapStringObject,
      ' toJson();',
    ]));
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
        case OmittedTypeAnnotation():
          buffer.write('<omitted>');
        default:
          buffer.write(part);
      }
    }
  }
}

extension on NamedTypeAnnotation {
  /// Follows the declaration of this type through any type aliases, until it
  /// reaches a [ClassDeclaration], or returns null if it does not bottom out on
  /// a class.
  Future<ClassDeclaration?> classDeclaration(DefinitionBuilder builder) async {
    var typeDecl = await builder.typeDeclarationOf(identifier);
    while (typeDecl is TypeAliasDeclaration) {
      final aliasedType = typeDecl.aliasedType;
      if (aliasedType is! NamedTypeAnnotation) {
        builder.report(Diagnostic(
            DiagnosticMessage(
                'Only fields with named types are allowed on serializable '
                'classes',
                target: asDiagnosticTarget),
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
              target: asDiagnosticTarget),
          Severity.error));
      return null;
    }
    return typeDecl;
  }
}
