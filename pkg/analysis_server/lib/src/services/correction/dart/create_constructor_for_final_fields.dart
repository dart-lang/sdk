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
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateConstructorForFinalFields extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

  FieldDeclaration? get _errorFieldDeclaration {
    if (node is VariableDeclaration) {
      final fieldDeclaration = node.parent?.parent;
      return fieldDeclaration?.ifTypeOrNull();
    }
    return null;
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

  Future<void> _forFlutterClass(_FixContext fixContext) async {
    // Specialize for Flutter widgets.
    var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
    if (keyClass == null) {
      return;
    }

    if (unit.featureSet.isEnabled(Feature.super_parameters)) {
      await _withSuperParameters(fixContext);
    } else {
      await _withoutSuperParameters(
        fixContext: fixContext,
        keyClass: keyClass,
      );
    }
  }

  Future<void> _notFlutter({
    required _FixContext fixContext,
    required bool isConst,
  }) async {
    final fieldNames = fixContext.variableLists
        .expand((variableList) => variableList.variables)
        .where((variable) => variable.initializer == null)
        .map((variable) => variable.name.lexeme)
        .toList();

    final location = fixContext.location;
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        if (isConst) {
          builder.write('const ');
        }
        builder.writeConstructorDeclaration(
          fixContext.containerName,
          fieldNames: fieldNames,
        );
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _withoutSuperParameters({
    required _FixContext fixContext,
    required ClassElement keyClass,
  }) async {
    final location = fixContext.location;
    var isNonNullable = unit.featureSet.isEnabled(Feature.non_nullable);
    await fixContext.builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        builder.writeType(
          keyClass.instantiate(
            typeArguments: const [],
            nullabilitySuffix: isNonNullable
                ? NullabilitySuffix.question
                : NullabilitySuffix.star,
          ),
        );
        builder.write(' key');

        _writeParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
          isNonNullable: isNonNullable,
        );

        builder.write('}) : super(key: key);');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _withSuperParameters(_FixContext fixContext) async {
    await fixContext.builder.addDartFileEdit(file, (builder) {
      final location = fixContext.location;
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write('const ');
        builder.write(fixContext.containerName);
        builder.write('({');
        builder.write('super.key');

        _writeParameters(
          builder: builder,
          variableLists: fixContext.variableLists,
          isNonNullable: true,
        );

        builder.write('});');
        builder.write(location.suffix);
      });
    });
  }

  void _writeParameters({
    required DartEditBuilder builder,
    required List<VariableDeclarationList> variableLists,
    required bool isNonNullable,
  }) {
    var childrenFields = <String>[];
    var childrenNullables = <bool>[];
    for (var variableList in variableLists) {
      var fieldNames = variableList.variables
          .where((v) => v.initializer == null)
          .map((v) => v.name.lexeme);

      final hasNullableType = variableList.type?.type?.nullabilitySuffix ==
          NullabilitySuffix.question;

      for (var fieldName in fieldNames) {
        if (fieldName == 'child' || fieldName == 'children') {
          childrenFields.add(fieldName);
          childrenNullables.add(hasNullableType);
          continue;
        }
        builder.write(', ');
        if (isNonNullable && !hasNullableType) {
          builder.write('required ');
        }
        builder.write('this.');
        builder.write(fieldName);
      }
    }
    for (var i = 0; i < childrenFields.length; i++) {
      var fieldName = childrenFields[i];
      var nullableField = childrenNullables[i];
      builder.write(', ');
      if (isNonNullable && !nullableField) {
        builder.write('required ');
      }
      builder.write('this.');
      builder.write(fieldName);
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
