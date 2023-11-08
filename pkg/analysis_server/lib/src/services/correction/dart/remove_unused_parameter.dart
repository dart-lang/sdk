// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnusedParameter extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedAutomatically => false;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNUSED_PARAMETER;

  @override
  FixKind? get multiFixKind => DartFixKind.REMOVE_UNUSED_PARAMETER_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // To work for the unused_parameter hint as well as the lint, we must
    // allow for passing in `SimpleIdentifier`s.
    var maybeParameter = node;
    var maybeParameterParent = maybeParameter.parent;
    if (maybeParameter is SimpleIdentifier && maybeParameterParent != null) {
      maybeParameter = maybeParameterParent;
    }

    var parameter = maybeParameter;
    if (parameter is! FormalParameter) {
      return;
    }

    var parent = parameter.parent;
    if (parent is DefaultFormalParameter) {
      parameter = parent;
    }

    var parameterList = parameter.parent;
    if (parameterList is! FormalParameterList) {
      return;
    }

    var parameters = parameterList.parameters;
    var index = parameters.indexOf(parameter);
    final parameter_final = parameter;
    await builder.addDartFileEdit(file, (builder) {
      if (index == 0) {
        // Remove the first parameter in the list.
        if (parameters.length == 1) {
          // There is only one parameter. By removing everything inside the
          // parentheses we also remove any square brackets or curly braces.
          builder.addDeletion(range.endStart(
              parameterList.leftParenthesis, parameterList.rightParenthesis));
        } else {
          var following = parameters[1];
          if (parameter_final.isRequiredPositional &&
              !following.isRequiredPositional) {
            // The parameter to be removed and the following parameter are not
            // of the same kind, so there is a delimiter between them that we
            // can't delete.
            var leftDelimiter = parameterList.leftDelimiter;
            if (leftDelimiter != null) {
              builder.addDeletion(range.startStart(parameter, leftDelimiter));
            } else {
              // Invalid code `C(foo, bar = 1)`.
              builder.addDeletion(range.startStart(parameter, following));
            }
          } else {
            // The parameter to be removed and the following parameter are of
            // the same kind, so there is no delimiter between them.
            builder.addDeletion(range.startStart(parameter, following));
          }
        }
      } else {
        var preceding = parameters[index - 1];
        if (preceding.isRequiredPositional &&
            !parameter_final.isRequiredPositional) {
          // The parameter to be removed and the preceding parameter are not
          // of the same kind, so there is a delimiter between them.
          if (index == parameters.length - 1) {
            // The parameter to be removed is the only parameter between the
            // delimiters, so remove the delimiters with the parameter.
            var trailingToken = parameterList.rightParenthesis;
            var previous = trailingToken.previous;
            if (previous != null && previous.type == TokenType.COMMA) {
              // Leave the trailing comma if there is one.
              trailingToken = previous;
            }
            builder.addDeletion(range.endStart(preceding, trailingToken));
          } else {
            // The parameter to be removed is the first inside the delimiters
            // but the delimiters should be left.
            var following = parameters[index + 1];
            builder.addDeletion(range.startStart(parameter, following));
          }
        } else {
          // The parameter to be removed and the preceding parameter are of
          // the same kind, so there is no delimiter between them.
          builder.addDeletion(range.endEnd(preceding, parameter));
        }
      }
    });
  }
}
