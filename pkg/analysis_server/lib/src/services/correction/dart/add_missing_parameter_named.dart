// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingParameterNamed extends ResolvedCorrectionProducer {
  String _parameterName = '';

  AddMissingParameterNamed({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_parameterName];

  @override
  FixKind get fixKind => DartFixKind.addMissingParameterNamed;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Prepare the name of the missing parameter.
    var node = this.node;
    if (node is! SimpleIdentifier) {
      return;
    }
    _parameterName = node.name;

    // We expect that the node is part of a NamedExpression.
    var namedExpression = node.parent?.parent;
    if (namedExpression is! NamedExpression) {
      return;
    }

    // We should be in an ArgumentList.
    var argumentList = namedExpression.parent;
    if (argumentList is! ArgumentList) {
      return;
    }

    // Prepare the invoked element.
    var context = ExecutableParameters.forInvocation(
      sessionHelper,
      argumentList.parent,
    );
    if (context == null) {
      return;
    }

    // We cannot add named parameters when there are positional positional.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    Future<void> addParameter(int? offset, String prefix, String suffix) async {
      if (offset != null) {
        await builder.addDartFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder.writeParameterMatchingArgument(
              namedExpression,
              0,
              <String>{},
            );
            builder.write(suffix);
          });
        });
      }
    }

    if (context.named.isNotEmpty) {
      var lastFirst = context.named.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await addParameter(prevNode?.end, ', ', '');
    } else if (context.required.isNotEmpty) {
      var lastFirst = context.required.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await addParameter(prevNode?.end, ', {', '}');
    } else {
      var parameterList = await context.getParameterList();
      await addParameter(parameterList?.leftParenthesis.end, '{', '}');
    }
  }
}
