// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingEnumCaseClauses extends CorrectionProducer {
  @override
  // Adding the missing case is not a sufficient fix (user logic needs adding
  // too).
  bool get canBeAppliedInBulk => false;

  @override
  // Adding the missing case is not a sufficient fix (user logic needs adding
  // too).
  bool get canBeAppliedToFile => false;

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var statement = node;
    if (statement is! SwitchStatement) {
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
      var enumElement = expressionType.element;
      if (enumElement is EnumElement) {
        enumName = enumElement.name;
        for (var field in enumElement.fields) {
          if (field.isEnumConstant) {
            unhandledEnumCases.add(field.name);
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
          var element = expression.staticElement;
          if (element is PropertyAccessorElement) {
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
    var singleIndent = utils.getIndent(1);
    var location = utils.newCaseClauseAtEndLocation(
      switchKeyword: statement.switchKeyword,
      leftBracket: statement.leftBracket,
      rightBracket: statement.rightBracket,
    );

    var prefixString = prefix.isNotEmpty ? '$prefix.' : '';
    final enumName_final = '$prefixString$enumName';
    var isLeftBracketSynthetic = statement.leftBracket.isSynthetic;
    var insertionOffset = isLeftBracketSynthetic
        ? statement.rightParenthesis.end
        : location.offset;
    await builder.addDartFileEdit(file, (builder) {
      // TODO(brianwilkerson) Consider inserting the names in order into the
      //  switch statement.
      builder.addInsertion(insertionOffset, (builder) {
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

        if (isLeftBracketSynthetic) {
          builder.write(' {');
        }
        builder.write(location.prefix);

        for (var constantName in unhandledEnumCases) {
          addMissingCase('$enumName_final.$constantName');
        }
        if (unhandledNullValue) {
          addMissingCase('null');
        }

        builder.write(location.suffix);
        if (statement.rightBracket.isSynthetic) {
          builder.write('}');
        }
      });
    });
  }

  /// Return the shortest prefix for the [element], or an empty String if not
  /// found.
  String _importPrefix(Element element) {
    var shortestPrefix = '';
    for (var directive in unit.directives) {
      if (directive is ImportDirective) {
        var namespace = directive.element?.namespace;
        if (namespace != null) {
          if (namespace.definedNames.containsValue(element)) {
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
