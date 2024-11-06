// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateParameter extends ResolvedCorrectionProducer {
  String _parameterName = '';

  CreateParameter({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_parameterName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    _parameterName = nameNode.name;
    // prepare target Statement
    var parameters =
        node.thisOrAncestorOfType<FunctionExpression>()?.parameters ??
        node.thisOrAncestorOfType<MethodDeclaration>()?.parameters ??
        node.thisOrAncestorOfType<ConstructorDeclaration>()?.parameters;
    if (parameters == null) {
      return;
    }

    var requiredPositionals = parameters.parameters.where(
      (p) => p.isRequiredPositional,
    );
    var namedParameters = parameters.parameters.where((p) => p.isNamed);
    var somethingAfterPositionals =
        requiredPositionals.isNotEmpty &&
        parameters.parameters.any((p) => !p.isRequiredPositional);
    var somethingBeforeNamed =
        requiredPositionals.isEmpty &&
        parameters.parameters.any((p) => !p.isNamed);
    var hasFollowingParameters =
        somethingAfterPositionals || somethingBeforeNamed;

    // compute type
    var type =
        inferUndefinedExpressionType(nameNode) ?? typeProvider.dynamicType;
    var lastRequiredPositional = requiredPositionals.lastOrNull;
    var lastNamed = namedParameters.lastOrNull;
    var hasPreviousParameters =
        lastRequiredPositional != null || lastNamed != null;
    var last = lastRequiredPositional ?? lastNamed;
    var trailingComma =
        parameters.parameters.lastOrNull?.endToken.next?.lexeme == ',';

    int insertionToken;
    if (hasPreviousParameters) {
      if (trailingComma) {
        // After comma
        insertionToken = last!.endToken.next!.end;
      } else if (hasFollowingParameters) {
        // After whitespace after comma
        insertionToken = last!.endToken.next!.end + 1;
      } else {
        // After last, as there is no comma
        insertionToken = last!.end;
      }
    } else {
      // At first position
      insertionToken = parameters.leftParenthesis.end;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(insertionToken, (builder) {
        //prefix
        if (hasPreviousParameters) {
          if (trailingComma) {
            builder.writeln();
            var whitespace = utils.getNodePrefix(last!);
            builder.write(whitespace);
          } else if (!hasFollowingParameters) {
            builder.write(', ');
          }
        }
        builder.writeParameter(
          _parameterName,
          type: type,
          nameGroupName: 'NAME',
          typeGroupName: 'TYPE',
          isRequiredType: true,
          isRequiredNamed:
              last != null &&
              last == lastNamed &&
              type.nullabilitySuffix != NullabilitySuffix.question,
        );
        //suffix
        if (trailingComma) {
          builder.write(',');
        } else if (hasFollowingParameters) {
          builder.write(', ');
        }
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
  }
}
