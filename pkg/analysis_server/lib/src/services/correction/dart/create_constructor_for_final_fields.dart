// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/object.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:collection/collection.dart';

class CreateConstructorForFinalFields extends CorrectionProducer {
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
        resolvedResult.session, classDeclaration);
    if (targetLocation == null) {
      return;
    }

    final fixContext = _FixContext(
      builder: builder,
      containerName: className,
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
        location: targetLocation,
        variableLists: variableLists,
      ),
      isConst: true,
    );
  }

  List<_Field> _fieldsToWrite(
    List<VariableDeclarationList> variableLists,
  ) {
    final result = <_Field>[];
    for (var variableList in variableLists) {
      final type = variableList.type?.type;
      final hasNonNullableType =
          type != null && typeSystem.isPotentiallyNonNullable(type);

      for (final field in variableList.variables) {
        if (field.initializer == null) {
          result.add(
            _Field(
              name: field.name.lexeme,
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

    final location = fixContext.location;
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        if (isConst) {
          builder.write('const ');
        }
        builder.write(fixContext.containerName);
        builder.write('(');
        switch (_style) {
          case _Style.requiredNamed:
            builder.write('{');
            fields.forEachIndexed((index, field) {
              if (index > 0) {
                builder.write(', ');
              }
              builder.write('required this.');
              builder.write(field.name);
            });
            builder.write('}');
          case _Style.requiredPositional:
            fields.forEachIndexed((index, field) {
              if (index > 0) {
                builder.write(', ');
              }
              builder.write('this.');
              builder.write(field.name);
            });
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
    final childrenLast = [
      ...fields.whereNot((field) => field.isChild),
      ...fields.where((field) => field.isChild),
    ];

    for (final field in childrenLast) {
      builder.write(', ');
      if (_hasNonNullableFeature && field.hasNonNullableType) {
        builder.write('required ');
      }
      builder.write('this.');
      builder.write(field.name);
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
  final String name;
  final bool hasNonNullableType;

  _Field({
    required this.name,
    required this.hasNonNullableType,
  });

  bool get isChild {
    return const {'child', 'children'}.contains(name);
  }
}

class _FixContext {
  final ChangeBuilder builder;
  final String containerName;
  final InsertionLocation location;
  final List<VariableDeclarationList> variableLists;

  _FixContext({
    required this.builder,
    required this.containerName,
    required this.location,
    required this.variableLists,
  });
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
