// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/executable_parameters.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
    if (node is NamedArgument) {
      await _handleArgumentNode(node, builder);
    } else if (node is SuperFormalParameter) {
      await _handleSuperFormalParameter(node, builder);
    }
  }

  Future<void> _addParameter(
    ChangeBuilder builder,
    ExecutableParameters context,
    int? offset,
    String prefix,
    String suffix, {
    NamedArgument? namedExpression,
    SuperFormalParameter? superFormalParameter,
  }) async {
    assert(
      (namedExpression != null) != (superFormalParameter != null),
      'Either namedExpression or superFormalParameter must be provided.',
    );
    if (offset != null) {
      if (namedExpression != null) {
        await builder.addDartFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            var type = namedExpression.argumentExpression.staticType;
            builder.writeFormalParameter(
              namedExpression.name.lexeme,
              type: type,
              isRequiredNamed:
                  type != null && typeSystem.isPotentiallyNonNullable(type),
            );
            builder.write(suffix);
          });
        });
      } else if (superFormalParameter != null) {
        await builder.addDartFileEdit(context.file, (builder) {
          builder.addInsertion(offset, (builder) {
            builder.write(prefix);
            var type = superFormalParameter.type?.type;
            if (superFormalParameter.defaultClause case var defaultClause?) {
              type ??= defaultClause.value.staticType;
            }
            builder.writeFormalParameter(
              superFormalParameter.name.lexeme,
              type: type,
              isRequiredNamed:
                  type != null && typeSystem.isPotentiallyNonNullable(type),
            );
            builder.write(suffix);
          });
        });
      }
    }
  }

  Future<void> _handleArgumentNode(
    NamedArgument namedExpression,
    ChangeBuilder builder,
  ) async {
    _parameterName = namedExpression.name.lexeme;
    // It isn't valid to have a private named parameter that is not assigning a
    // value to a field, so we can't support this case.
    if (Identifier.isPrivateName(_parameterName)) return;

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

    // We can't add named parameters when there are optional positional
    // parameters.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    if (context.named.isNotEmpty) {
      var lastFirst = context.named.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await _addParameter(
        builder,
        context,
        prevNode?.end,
        ', ',
        '',
        namedExpression: namedExpression,
      );
    } else if (context.required.isNotEmpty) {
      var lastFirst = context.required.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await _addParameter(
        builder,
        context,
        prevNode?.end,
        ', {',
        '}',
        namedExpression: namedExpression,
      );
    } else {
      var parameterList = await context.getParameterList();
      await _addParameter(
        builder,
        context,
        parameterList?.leftParenthesis.end,
        '{',
        '}',
        namedExpression: namedExpression,
      );
    }
  }

  Future<void> _handleSuperFormalParameter(
    SuperFormalParameter node,
    ChangeBuilder builder,
  ) async {
    Element? element;
    if (node.parent case FormalParameterList(
      parent: ConstructorDeclaration(:var declaredFragment?),
    )) {
      element = declaredFragment.element.superConstructor;
    }

    // Prepare the invoked element.
    var context = ExecutableParameters.forInvocation(
      sessionHelper,
      null,
      element: element,
    );
    if (context == null) {
      return;
    }

    // We cannot add named parameters when there are positional positional.
    if (context.optionalPositional.isNotEmpty) {
      return;
    }

    if (context.named.isNotEmpty) {
      var lastFirst = context.named.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await _addParameter(
        builder,
        context,
        prevNode?.end,
        superFormalParameter: node,
        ', ',
        '',
      );
    } else if (context.required.isNotEmpty) {
      var lastFirst = context.required.last.firstFragment;
      var prevNode = await context.getParameterNode(lastFirst);
      await _addParameter(
        builder,
        context,
        prevNode?.end,
        superFormalParameter: node,
        ', {',
        '}',
      );
    } else {
      var parameterList = await context.getParameterList();
      await _addParameter(
        builder,
        context,
        parameterList?.leftParenthesis.end,
        superFormalParameter: node,
        '{',
        '}',
      );
    }
  }
}
