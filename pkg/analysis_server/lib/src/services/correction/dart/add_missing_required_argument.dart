// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingRequiredArgument extends CorrectionProducer {
  /// The name of the parameter that was missing.
  String _missingParameterName;

  @override
  List<Object> get fixArguments => [_missingParameterName];

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_REQUIRED_ARGUMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    InstanceCreationExpression creation;
    Element targetElement;
    ArgumentList argumentList;

    if (node is SimpleIdentifier || node is ConstructorName) {
      var invocation = node.parent;
      if (invocation is MethodInvocation) {
        targetElement = invocation.methodName.staticElement;
        argumentList = invocation.argumentList;
      } else {
        creation =
            invocation.thisOrAncestorOfType<InstanceCreationExpression>();
        if (creation != null) {
          targetElement = creation.constructorName.staticElement;
          argumentList = creation.argumentList;
        }
      }
    }

    if (targetElement is ExecutableElement) {
      // Format: "Missing required argument 'foo'."
      var messageParts = diagnostic.problemMessage.message.split("'");
      if (messageParts.length < 2) {
        return;
      }
      _missingParameterName = messageParts[1];

      var missingParameter = targetElement.parameters.firstWhere(
          (p) => p.name == _missingParameterName,
          orElse: () => null);
      if (missingParameter == null) {
        return;
      }

      int offset;
      var hasTrailingComma = false;
      var insertBetweenParams = false;
      List<Expression> arguments = argumentList.arguments;
      if (arguments.isEmpty) {
        offset = argumentList.leftParenthesis.end;
      } else {
        var lastArgument = arguments.last;
        offset = lastArgument.end;
        hasTrailingComma = lastArgument.endToken.next.type == TokenType.COMMA;

        if (lastArgument is NamedExpression &&
            flutter.isWidgetExpression(creation)) {
          if (flutter.isChildArgument(lastArgument) ||
              flutter.isChildrenArgument(lastArgument)) {
            offset = lastArgument.offset;
            hasTrailingComma = true;
            insertBetweenParams = true;
          }
        }
      }
      var defaultValue = getDefaultStringParameterValue(missingParameter,
          withNullability: libraryElement.isNonNullableByDefault &&
              missingParameter.library.isNonNullableByDefault);

      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(offset, (builder) {
          if (arguments.isNotEmpty && !insertBetweenParams) {
            builder.write(', ');
          }

          builder.write('$_missingParameterName: ');

          // Use defaultValue.cursorPosition if it's not null.
          if (defaultValue?.cursorPosition != null) {
            builder.write(
                defaultValue.text.substring(0, defaultValue.cursorPosition));
            builder.selectHere();
            builder.write(
                defaultValue.text.substring(defaultValue.cursorPosition));
          } else {
            builder.addSimpleLinkedEdit('VALUE', defaultValue?.text);
          }

          if (flutter.isWidgetExpression(creation)) {
            // Insert a trailing comma after Flutter instance creation params.
            if (!hasTrailingComma) {
              builder.write(',');
            } else if (insertBetweenParams) {
              builder.writeln(',');

              // Insert indent before the child: or children: param.
              var indent = utils.getLinePrefix(offset);
              builder.write(indent);
            }
          }
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddMissingRequiredArgument newInstance() =>
      AddMissingRequiredArgument();
}
