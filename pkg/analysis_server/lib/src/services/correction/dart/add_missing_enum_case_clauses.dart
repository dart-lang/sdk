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
    var enumConstantNames = <String>[];
    var expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      var enumElement = expressionType.element;
      if (enumElement is EnumElement) {
        enumName = enumElement.name;
        for (var field in enumElement.fields) {
          if (field.isEnumConstant) {
            enumConstantNames.add(field.name);
          }
        }
        prefix = _importPrefix(enumElement);
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
            enumConstantNames.remove(element.name);
          }
        }
      }
    }
    if (enumConstantNames.isEmpty) {
      return;
    }

    var statementIndent = utils.getLinePrefix(statement.offset);
    var singleIndent = utils.getIndent(1);
    var location = utils.newCaseClauseAtEndLocation(statement);

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
        if (isLeftBracketSynthetic) {
          builder.write(' {');
        }
        builder.write(location.prefix);
        for (var constantName in enumConstantNames) {
          builder.write(statementIndent);
          builder.write(singleIndent);
          builder.write('case ');
          builder.write(enumName_final);
          builder.write('.');
          builder.write(constantName);
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
