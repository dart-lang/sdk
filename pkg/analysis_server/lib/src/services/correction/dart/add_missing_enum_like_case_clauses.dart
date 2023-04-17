// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingEnumLikeCaseClauses extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  // TODO: Consider enabling this lint for fix all in file.
  // @override
  // FixKind? get multiFixKind => super.multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SwitchStatement) {
      var expressionType = node.expression.staticType;
      if (expressionType is! InterfaceType) {
        return;
      }
      var classElement = expressionType.element;
      var className = classElement.name;
      var caseNames = _caseNames(node);
      var missingNames = _constantNames(classElement)
        ..removeWhere((e) => caseNames.contains(e));
      missingNames.sort();

      var statementIndent = utils.getLinePrefix(node.offset);
      var singleIndent = utils.getIndent(1);
      var location = utils.newCaseClauseAtEndLocation(
        switchKeyword: node.switchKeyword,
        leftBracket: node.leftBracket,
        rightBracket: node.rightBracket,
      );

      await builder.addDartFileEdit(file, (builder) {
        // TODO(brianwilkerson) Consider inserting the names in order into the
        //  switch statement.
        builder.addInsertion(location.offset, (builder) {
          builder.write(location.prefix);
          for (var name in missingNames) {
            builder.write(statementIndent);
            builder.write(singleIndent);
            builder.write('case ');
            builder.write(className);
            builder.write('.');
            builder.write(name);
            builder.writeln(':');
            builder.write(statementIndent);
            builder.write(singleIndent);
            builder.write(singleIndent);
            builder.writeln('// TODO: Handle this case.');
            builder.write(statementIndent);
            builder.write(singleIndent);
            builder.write(singleIndent);
            builder.writeln('break;');
          }
          builder.write(location.suffix);
        });
      });
    }
  }

  /// Return the names of the constants already in a case clause in the
  /// [statement].
  List<String> _caseNames(SwitchStatement statement) {
    var caseNames = <String>[];
    for (var member in statement.members) {
      if (member is SwitchCase) {
        var expression = member.expression;
        if (expression is Identifier) {
          var element = expression.staticElement;
          if (element is PropertyAccessorElement) {
            caseNames.add(element.name);
          }
        } else if (expression is PropertyAccess) {
          caseNames.add(expression.propertyName.name);
        }
      }
    }
    return caseNames;
  }

  /// Return the names of the constants defined in [classElement].
  List<String> _constantNames(InterfaceElement classElement) {
    var type = classElement.thisType;
    var constantNames = <String>[];
    for (var field in classElement.fields) {
      // Ensure static const.
      if (field.isSynthetic || !field.isConst || !field.isStatic) {
        continue;
      }
      // Check for type equality.
      if (field.type != type) {
        continue;
      }
      constantNames.add(field.name);
    }
    return constantNames;
  }
}
