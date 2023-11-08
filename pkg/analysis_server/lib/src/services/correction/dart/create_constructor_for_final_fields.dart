// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class CreateConstructorForFinalFields extends ResolvedCorrectionProducer {
  final _Style _style;

  CreateConstructorForFinalFields.requiredNamed()
      : _style = _Style.requiredNamed;

  CreateConstructorForFinalFields.requiredPositional()
      : _style = _Style.requiredPositional;

  @override
  FixKind get fixKind => _style.fixKind;

  FieldDeclaration? get _errorFieldDeclaration {
    if (node is VariableDeclaration) {
      final fieldDeclaration = node.parent?.parent;
      return fieldDeclaration?.ifTypeOrNull();
    }
    return null;
  }

  bool get _hasNonNullableFeature {
    return unit.featureSet.isEnabled(Feature.non_nullable);
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final fieldDeclaration = _errorFieldDeclaration;
    if (fieldDeclaration == null) {
      return;
    }

    final containerDeclaration = fieldDeclaration.parent;
    switch (containerDeclaration) {
      case ClassDeclaration():
        await _classDeclaration(
          builder: builder,
          classDeclaration: containerDeclaration,
        );
      case EnumDeclaration():
        await _enumDeclaration(
          builder: builder,
          enumDeclaration: containerDeclaration,
        );
    }
  }

  Future<void> _classDeclaration({
    required ChangeBuilder builder,
    required ClassDeclaration classDeclaration,
  }) async {
    var className = classDeclaration.name.lexeme;
    var superType = classDeclaration.declaredElement?.supertype;
    if (superType == null) {
      return;
    }

    final variableLists = _interestingVariableLists(
      classDeclaration.members,
    );

    // prepare location for a new constructor
    var targetLocation = utils.prepareNewConstructorLocation(
        unitResult.session, classDeclaration, unitResult.file);
    if (targetLocation == null) {
      return;
    }

    final fixContext = _FixContext(
      builder: builder,
      containerName: className,
      superType: superType,
      location: targetLocation,
      variableLists: variableLists,
    );

    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      await _forFlutterClass(fixContext);
    } else {
      await _notFlutter(
        fixContext: fixContext,
        isConst: false,
      );
    }
  }

  Future<void> _enumDeclaration({
    required ChangeBuilder builder,
    required EnumDeclaration enumDeclaration,
  }) async {
    final enumName = enumDeclaration.name.lexeme;
    final variableLists = _interestingVariableLists(
      enumDeclaration.members,
    );

    final targetLocation =
        utils.prepareEnumNewConstructorLocation(enumDeclaration);

    await _notFlutter(
      fixContext: _FixContext(
        builder: builder,
        containerName: enumName,
        superType: null,
        location: targetLocation,
        variableLists: variableLists,
      ),
      isConst: true,
    );
  }

  List<_Field>? _fieldsToWrite(
    List<VariableDeclarationList> variableLists,
  ) {
    final result = <_Field>[];
    for (var variableList in variableLists) {
      final type = variableList.type?.type;
      final hasNonNullableType =
          type != null && typeSystem.isPotentiallyNonNullable(type);

      for (final field in variableList.variables) {
        final typeAnnotation = variableList.type;
        if (typeAnnotation == null) {
          return null;
        }
        if (field.initializer == null) {
          final fieldName = field.name.lexeme;
          final namedFormalParameterName =
              _Field.computeNamedFormalParameterName(fieldName);
          if (namedFormalParameterName == null) {
            return null;
          }
          result.add(
            _Field(
              typeAnnotation: typeAnnotation,
              fieldName: fieldName,
              namedFormalParameterName: namedFormalParameterName,
              hasNonNullableType: hasNonNullableType,
            ),
          );
        }
      }
    }
    return result;
  }

  Future<void> _forFlutterClass(_FixContext fixContext) async {
    if (unit.featureSet.isEnabled(Feature.super_parameters)) {
      await _forFlutterWithSuperParameters(fixContext);
    } else {
      await _forFlutterWithoutSuperParameters(fixContext);
    }
  }

  Future<void> _forFlutterWithoutSuperParameters(
    _FixContext fixContext,
  ) async {
    final keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
    if (keyClass == null) {
      return;
    }

    final location = fixContext.location;
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        builder.writeType(
          keyClass.instantiate(
            typeArguments: const [],
            nullabilitySuffix: _hasNonNullableFeature
                ? NullabilitySuffix.question
                : NullabilitySuffix.star,
          ),
        );
        builder.write(' key');

        _writeFlutterParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
        );

        builder.write('}) : super(key: key);');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _forFlutterWithSuperParameters(
    _FixContext fixContext,
  ) async {
    await fixContext.builder.addDartFileEdit(file, (builder) {
      final location = fixContext.location;
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        builder.write('super.key');

        _writeFlutterParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
        );

        builder.write('});');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _notFlutter({
    required _FixContext fixContext,
    required bool isConst,
  }) async {
    final fields = _fieldsToWrite(fixContext.variableLists);
    if (fields == null) {
      return;
    }

    switch (_style) {
      case _Style.requiredNamed:
        await _notFlutterNamed(
          fixContext: fixContext,
          isConst: isConst,
          fields: fields,
        );
      case _Style.requiredPositional:
        await _notFlutterRequiredPositional(
          fixContext: fixContext,
          isConst: isConst,
          fields: fields,
        );
    }
  }

  Future<void> _notFlutterNamed({
    required _FixContext fixContext,
    required bool isConst,
    required List<_Field> fields,
  }) async {
    final fieldsForInitializers = <_Field>[];

    final location = fixContext.location;
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        if (isConst) {
          builder.write('const ');
        }
        builder.write(fixContext.containerName);
        builder.write('({');
        var hasWritten = false;
        final superNamed = fixContext.superNamed;
        if (superNamed != null) {
          for (final formalParameter in superNamed) {
            if (hasWritten) {
              builder.write(', ');
            }
            if (formalParameter.isRequiredNamed) {
              builder.write('required ');
            }
            builder.write('super.');
            builder.write(formalParameter.name);
            hasWritten = true;
          }
        }
        for (final field in fields) {
          if (hasWritten) {
            builder.write(', ');
          }
          if (field.namedFormalParameterName == field.fieldName) {
            builder.write('required this.');
            builder.write(field.fieldName);
          } else {
            builder.write('required ');
            builder.write(
              utils.getNodeText(field.typeAnnotation),
            );
            builder.write(' ');
            builder.write(field.namedFormalParameterName);
            fieldsForInitializers.add(field);
          }
          hasWritten = true;
        }
        builder.write('})');

        if (fieldsForInitializers.isNotEmpty) {
          final code = fieldsForInitializers.map((field) {
            return '${field.fieldName} = ${field.namedFormalParameterName}';
          }).join(', ');
          builder.write(' : $code');
        }

        builder.write(';');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _notFlutterRequiredPositional({
    required _FixContext fixContext,
    required bool isConst,
    required List<_Field> fields,
  }) async {
    final location = fixContext.location;
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        if (isConst) {
          builder.write('const ');
        }
        builder.write(fixContext.containerName);
        builder.write('(');
        var hasWritten = false;
        for (final field in fields) {
          if (hasWritten) {
            builder.write(', ');
          }
          builder.write('this.');
          builder.write(field.fieldName);
          hasWritten = true;
        }
        builder.write(');');
        builder.write(location.suffix);
      });
    });
  }

  void _writeFlutterParameters({
    required DartEditBuilder builder,
    required List<VariableDeclarationList> variableLists,
  }) {
    final fields = _fieldsToWrite(variableLists);
    if (fields == null) {
      return;
    }

    final childrenLast = fields.stablePartition(
      (field) => !field.isChild,
    );

    for (final field in childrenLast) {
      builder.write(', ');
      if (_hasNonNullableFeature && field.hasNonNullableType) {
        builder.write('required ');
      }
      builder.write('this.');
      builder.write(field.fieldName);
    }
  }

  static List<VariableDeclarationList> _interestingVariableLists(
    List<ClassMember> members,
  ) {
    return members
        .whereType<FieldDeclaration>()
        .map((e) => e.fields)
        .where((e) => e.isFinal && !e.isLate)
        .toList();
  }
}

class _Field {
  final TypeAnnotation typeAnnotation;
  final String fieldName;
  final String namedFormalParameterName;
  final bool hasNonNullableType;

  _Field({
    required this.typeAnnotation,
    required this.fieldName,
    required this.namedFormalParameterName,
    required this.hasNonNullableType,
  });

  bool get isChild {
    return const {'child', 'children'}.contains(fieldName);
  }

  /// Returns the name for the corresponding named formal parameters, or
  /// `null` if such name cannot be computed, so that the quick fix cannot
  /// be computed.
  static String? computeNamedFormalParameterName(String fieldName) {
    var result = fieldName;
    while (true) {
      if (result.isEmpty) {
        return null;
      } else if (result.startsWith('_')) {
        result = result.substring(1);
      } else {
        return result;
      }
    }
  }
}

class _FixContext {
  final ChangeBuilder builder;
  final String containerName;
  final InterfaceType? superType;
  final InsertionLocation location;
  final List<VariableDeclarationList> variableLists;

  _FixContext({
    required this.builder,
    required this.containerName,
    required this.superType,
    required this.location,
    required this.variableLists,
  });

  List<ParameterElement>? get superNamed {
    final superConstructor = superType?.constructors.singleOrNull;
    if (superConstructor != null) {
      final superAll = superConstructor.parameters;
      final superNamed = superAll.where((e) => e.isNamed).toList();
      return superNamed.length == superAll.length ? superNamed : null;
    }
    return null;
  }
}

enum _Style {
  requiredNamed(
    fixKind: DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS_REQUIRED_NAMED,
  ),
  requiredPositional(
    fixKind: DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS,
  );

  final FixKind fixKind;

  const _Style({
    required this.fixKind,
  });
}
