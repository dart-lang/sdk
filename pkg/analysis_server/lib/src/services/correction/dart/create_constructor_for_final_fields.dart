// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
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

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier || node.parent is! VariableDeclaration) {
      return;
    }

    var classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
    if (classDeclaration == null) {
      return;
    }

    var className = classDeclaration.name.name;
    var superType = classDeclaration.declaredElement?.supertype;
    if (superType == null) {
      return;
    }

    var variableLists = <VariableDeclarationList>[];
    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        var variableList = member.fields;
        if (variableList.isFinal && !variableList.isLate) {
          variableLists.add(variableList);
        }
      }
    }
    // prepare location for a new constructor
    var targetLocation = utils.prepareNewConstructorLocation(
        resolvedResult.session, classDeclaration);
    if (targetLocation == null) {
      return;
    }

    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      // Specialize for Flutter widgets.
      var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
      if (keyClass == null) {
        return;
      }

      if (unit.featureSet.isEnabled(Feature.super_parameters)) {
        await _withSuperParameters(
            builder, targetLocation, className, variableLists);
      } else {
        await _withoutSuperParameters(
            builder, targetLocation, className, keyClass, variableLists);
      }
    } else {
      var fieldNames = <String>[];
      for (var variableList in variableLists) {
        fieldNames.addAll(variableList.variables
            .where((v) => v.initializer == null)
            .map((v) => v.name.name));
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(targetLocation.offset, (builder) {
          builder.write(targetLocation.prefix);
          builder.writeConstructorDeclaration(className,
              fieldNames: fieldNames);
          builder.write(targetLocation.suffix);
        });
      });
    }
  }

  Future<void> _withoutSuperParameters(
      ChangeBuilder builder,
      InsertionLocation targetLocation,
      String className,
      ClassElement keyClass,
      List<VariableDeclarationList> variableLists) async {
    var isNonNullable = unit.featureSet.isEnabled(Feature.non_nullable);
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.write('const ');
        builder.write(className);
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

        _writeParameters(builder, variableLists, isNonNullable);

        builder.write('}) : super(key: key);');
        builder.write(targetLocation.suffix);
      });
    });
  }

  Future<void> _withSuperParameters(
      ChangeBuilder builder,
      InsertionLocation targetLocation,
      String className,
      List<VariableDeclarationList> variableLists) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(targetLocation.offset, (builder) {
        builder.write(targetLocation.prefix);
        builder.write('const ');
        builder.write(className);
        builder.write('({');
        builder.write('super.key');

        _writeParameters(builder, variableLists, true);

        builder.write('});');
        builder.write(targetLocation.suffix);
      });
    });
  }

  void _writeParameters(DartEditBuilder builder,
      List<VariableDeclarationList> variableLists, bool isNonNullable) {
    var childrenFields = <String>[];
    var childrenNullables = <bool>[];
    for (var variableList in variableLists) {
      var fieldNames = variableList.variables
          .where((v) => v.initializer == null)
          .map((v) => v.name.name);

      for (var fieldName in fieldNames) {
        if (fieldName == 'child' || fieldName == 'children') {
          childrenFields.add(fieldName);
          childrenNullables.add(variableList.type?.type?.nullabilitySuffix ==
              NullabilitySuffix.question);
          continue;
        }
        builder.write(', ');
        if (isNonNullable &&
            variableList.type?.type?.nullabilitySuffix !=
                NullabilitySuffix.question) {
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
}
