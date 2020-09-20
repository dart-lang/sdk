// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddMissingParameterNamed extends CorrectionProducer {
  String _parameterName;

  @override
  List<Object> get fixArguments => [_parameterName];

  @override
  FixKind get fixKind => DartFixKind.ADD_MISSING_PARAMETER_NAMED;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Prepare the name of the missing parameter.
    if (this.node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier node = this.node;
    _parameterName = node.name;

    // We expect that the node is part of a NamedExpression.
    if (node.parent?.parent is! NamedExpression) {
      return;
    }
    NamedExpression namedExpression = node.parent.parent;

    // We should be in an ArgumentList.
    if (namedExpression.parent is! ArgumentList) {
      return;
    }
    var argumentList = namedExpression.parent;

    // Prepare the invoked element.
    var context = ExecutableParameters(sessionHelper, argumentList.parent);
    if (context == null) {
      return;
    }

    // We cannot add named parameters when there are positional positional.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    Future<void> addParameter(int offset, String prefix, String suffix) async {
      if (offset != null) {
        await builder.addDartFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            builder
                .writeParameterMatchingArgument(namedExpression, 0, <String>{});
            builder.write(suffix);
          });
        });
      }
    }

    if (context.named.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.named.last);
      await addParameter(prevNode?.end, ', ', '');
    } else if (context.required.isNotEmpty) {
      var prevNode = await context.getParameterNode(context.required.last);
      await addParameter(prevNode?.end, ', {', '}');
    } else {
      var parameterList = await context.getParameterList();
      await addParameter(parameterList?.leftParenthesis?.end, '{', '}');
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddMissingParameterNamed newInstance() => AddMissingParameterNamed();
}
