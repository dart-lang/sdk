// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateConstructorForFinalFields extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CREATE_CONSTRUCTOR_FOR_FINAL_FIELDS;

  bool get _isNonNullable => unit.featureSet.isEnabled(Feature.non_nullable);

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
    var superType = classDeclaration.declaredElement.supertype;

    // prepare names of uninitialized final fields
    var fieldNames = <String>[];
    for (var member in classDeclaration.members) {
      if (member is FieldDeclaration) {
        var variableList = member.fields;
        if (variableList.isFinal && !variableList.isLate) {
          fieldNames.addAll(variableList.variables
              .where((v) => v.initializer == null)
              .map((v) => v.name.name));
        }
      }
    }
    // prepare location for a new constructor
    var targetLocation = utils.prepareNewConstructorLocation(classDeclaration);

    if (flutter.isExactlyStatelessWidgetType(superType) ||
        flutter.isExactlyStatefulWidgetType(superType)) {
      // Specialize for Flutter widgets.
      var keyClass = await sessionHelper.getClass(flutter.widgetsUri, 'Key');
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(targetLocation.offset, (builder) {
          builder.write(targetLocation.prefix);
          builder.write('const ');
          builder.write(className);
          builder.write('({');
          builder.writeType(
            keyClass.instantiate(
              typeArguments: const [],
              nullabilitySuffix: _isNonNullable
                  ? NullabilitySuffix.question
                  : NullabilitySuffix.star,
            ),
          );
          builder.write(' key');

          var childrenFields = <String>[];
          for (var fieldName in fieldNames) {
            if (fieldName == 'child' || fieldName == 'children') {
              childrenFields.add(fieldName);
              continue;
            }
            builder.write(', this.');
            builder.write(fieldName);
          }
          for (var fieldName in childrenFields) {
            builder.write(', this.');
            builder.write(fieldName);
          }

          builder.write('}) : super(key: key);');
          builder.write(targetLocation.suffix);
        });
      });
    } else {
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateConstructorForFinalFields newInstance() =>
      CreateConstructorForFinalFields();
}
