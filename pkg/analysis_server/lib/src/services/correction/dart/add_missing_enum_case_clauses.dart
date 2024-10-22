// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingEnumCaseClauses extends ResolvedCorrectionProducer {
  AddMissingEnumCaseClauses({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Adding the missing case is not a sufficient fix (user logic needs
      // adding too).
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var statement = node;
    if (statement is! SwitchStatement) {
      return;
    }
    if (statement.rightParenthesis.isSynthetic) {
      return;
    }

    String? enumName;
    var prefix = '';

    // The missing enum case clauses can be caused by a missing enum case or, if
    // the expression is nullable, a missing `case null` entry. We first collect
    // all cases and then remove the ones that are already present.
    var unhandledEnumCases = <String>[];
    var unhandledNullValue = false;

    var expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      var enumElement = expressionType.element3;
      if (enumElement is EnumElement2) {
        enumName = enumElement.name;
        for (var field in enumElement.fields2) {
          if (field.isEnumConstant) {
            unhandledEnumCases.addIfNotNull(field.name);
          }
        }
        prefix = _importPrefix(enumElement);

        if (typeSystem.isNullable(expressionType)) {
          unhandledNullValue = true;
        }
      }
    }
    if (enumName == null) {
      return;
    }
    for (var member in statement.members) {
      if (member is SwitchCase) {
        var expression = member.expression;
        if (expression is Identifier) {
          var element = expression.element;
          if (element is GetterElement) {
            unhandledEnumCases.remove(element.name);
          }
        } else if (expression is NullLiteral) {
          unhandledNullValue = false;
        }
      }
    }
    if (!unhandledNullValue && unhandledEnumCases.isEmpty) {
      return;
    }

    var statementIndent = utils.getLinePrefix(statement.offset);
    var singleIndent = utils.oneIndent;

    var prefixString = prefix.isNotEmpty ? '$prefix.' : '';
    var enumName_final = '$prefixString$enumName';
    await builder.addDartFileEdit(file, (builder) {
      builder.insertCaseClauseAtEnd(
          switchKeyword: statement.switchKeyword,
          rightParenthesis: statement.rightParenthesis,
          leftBracket: statement.leftBracket,
          rightBracket: statement.rightBracket, (builder) {
        void addMissingCase(String expression) {
          builder.write(statementIndent);
          builder.write(singleIndent);
          builder.write('case ');
          builder.write(expression);
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

        // TODO(brianwilkerson): Consider inserting the names in order into the
        //  switch statement.
        for (var constantName in unhandledEnumCases) {
          addMissingCase('$enumName_final.$constantName');
        }
        if (unhandledNullValue) {
          addMissingCase('null');
        }
      });
    });
  }

  /// Return the shortest prefix for the [element], or an empty String if not
  /// found.
  String _importPrefix(Element2 element) {
    var shortestPrefix = '';
    for (var directive in unit.directives) {
      if (directive is ImportDirective) {
        var namespace = directive.element?.namespace;
        if (namespace != null) {
          if (namespace.definedNames2.containsValue(element)) {
            var prefix = directive.prefix?.name;
            if (prefix == null) {
              return '';
            } else if (shortestPrefix.isEmpty ||
                prefix.length < shortestPrefix.length) {
              shortestPrefix = prefix;
            }
          }
        }
      }
    }
    return shortestPrefix;
  }
}
