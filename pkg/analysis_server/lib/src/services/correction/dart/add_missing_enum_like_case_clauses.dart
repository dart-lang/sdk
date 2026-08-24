// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/extensions.dart';

class AddMissingEnumLikeCaseClauses extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.addMissingEnumCaseClauses;

  // TODO(brianwilkerson): Consider enabling this lint for fix all in file.
  // @override
  // FixKind? get multiFixKind => super.multiFixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is SwitchStatement) {
      var expressionType = node.expression.staticType;
      if (expressionType is! InterfaceType) {
        return;
      }
      var interfaceElement = expressionType.element;
      var enumDescription = interfaceElement.asEnumLikeType();
      if (enumDescription == null) {
        return;
      }

      var caseValues = _caseValues(node);
      var missingFields = <FieldElement>[];
      for (var entry in enumDescription.enumConstants.entries) {
        if (!caseValues.contains(entry.key)) {
          var field = _preferredField(entry.value);
          if (field.name != null) {
            missingFields.add(field);
          }
        }
      }
      missingFields.sort((a, b) => a.name!.compareTo(b.name!));

      var statementIndent = utils.getLinePrefix(node.offset);
      var singleIndent = utils.oneIndent;

      await builder.addDartFileEdit(file, (builder) {
        // TODO(brianwilkerson): Consider inserting the names in order into the
        //  switch statement.
        builder.insertCaseClauseAtEnd(
          switchKeyword: node.switchKeyword,
          rightParenthesis: node.rightParenthesis,
          leftBracket: node.leftBracket,
          rightBracket: node.rightBracket,
          (builder) {
            for (var field in missingFields) {
              builder.write(statementIndent);
              builder.write(singleIndent);
              builder.write('case ');
              builder.writeReference(interfaceElement);
              builder.write('.');
              builder.write(field.name!);
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
          },
        );
      });
    }
  }

  /// Return the values of the constants already in a case clause in the
  /// [statement].
  static Set<DartObject> _caseValues(SwitchStatement statement) {
    var caseValues = <DartObject>{};
    for (var member in statement.members) {
      Expression? expression;
      if (member is SwitchCase) {
        expression = member.expression.unParenthesized;
      } else if (member is SwitchPatternCase) {
        var pattern = member.guardedPattern.pattern.unParenthesized;
        if (pattern is ConstantPattern) {
          expression = pattern.expression.unParenthesized;
        }
      }

      Element? element = switch (expression) {
        Identifier(:var element) => element,
        PropertyAccess(:var propertyName) => propertyName.element,
        DotShorthandPropertyAccess(:var propertyName) => propertyName.element,
        _ => null,
      };
      if (element is GetterElement) {
        element = element.variable;
      }
      if (element is VariableElement) {
        var value = element.computeConstantValue();
        if (value != null) {
          caseValues.add(value);
        }
      }
    }
    return caseValues;
  }

  static FieldElement _preferredField(Set<FieldElement> fields) {
    return fields.firstWhere(
      (field) => !field.metadata.hasDeprecated,
      orElse: () => fields.first,
    );
  }
}
