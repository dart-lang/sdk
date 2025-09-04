// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddCallSuper extends ResolvedCorrectionProducer {
  var _addition = '';

  AddCallSuper({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Adding as the first statement is not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_addition];

  @override
  FixKind get fixKind => DartFixKind.ADD_CALL_SUPER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var methodDeclaration = node;
    if (methodDeclaration is! MethodDeclaration) return;

    var classFragment = methodDeclaration
        .thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredFragment;
    if (classFragment == null) return;
    var classElement = classFragment.element;

    var name = methodDeclaration.name.lexeme;
    var nameObj = Name.forLibrary(classElement.library, name);
    var overridden = classElement.getInheritedMember(nameObj);
    if (overridden == null) return;
    var overriddenNamedParameters = overridden.formalParameters
        .where((p) => p.isNamed)
        .map((p) => p.name);

    var body = methodDeclaration.body;
    var parameters = methodDeclaration.parameters?.parameters;
    var arguments = <String>[];
    if (parameters != null) {
      for (var i = 0; i < parameters.length; i++) {
        var p = parameters[i];
        var name = p.name?.lexeme;
        if (name == null) continue;
        if (p.isPositional) {
          if (i < overridden.formalParameters.length &&
              overridden.formalParameters[i].isPositional) {
            arguments.add(name);
          }
        } else if (overriddenNamedParameters.contains(name)) {
          arguments.add(p.isNamed ? '$name: $name' : name);
        }
      }
    }

    _addition = '$name(${arguments.join(', ')})';

    if (body is BlockFunctionBody) {
      await _block(builder, body.block);
    } else if (body is ExpressionFunctionBody) {
      await _expression(builder, body);
    }
  }

  Future<void> _block(ChangeBuilder builder, Block block) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(block.leftBracket.end, (builder) {
        builder.writeln();
        builder.write('${builder.getIndent(2)}super.$_addition;');
        if (block.statements.isEmpty) {
          builder.writeln();
          builder.writeIndent();
        }
      });
    });
  }

  Future<void> _expression(
    ChangeBuilder builder,
    ExpressionFunctionBody body,
  ) async {
    var expression = body.expression;
    var semicolon = body.semicolon;
    var prefix = utils.getLinePrefix(expression.offset);

    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      var prefixWithLine = eol + prefix + utils.oneIndent;

      builder.addSimpleReplacement(
        range.startStart(body.functionDefinition, expression),
        '{${prefixWithLine}super.$_addition;${prefixWithLine}return ',
      );

      builder.addSimpleReplacement(
        range.endEnd(expression, semicolon ?? expression),
        ';$eol$prefix}',
      );
    });
  }
}
