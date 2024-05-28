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
    var classElement = methodDeclaration
        .thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredElement;
    if (classElement == null) return;

    var name = methodDeclaration.name.lexeme;
    var nameObj = Name(classElement.library.source.uri, name);
    var overridden = InheritanceManager3().getInherited2(classElement, nameObj);
    if (overridden == null) return;
    var overriddenParameters = overridden.parameters.map((p) => p.name);

    var body = methodDeclaration.body;
    var parameters = methodDeclaration.parameters?.parameters;
    var argumentList = parameters
            ?.map((p) {
              var name = p.name?.lexeme;
              if (overriddenParameters.contains(name)) {
                return p.isNamed ? '$name: $name' : name;
              }
              return null;
            })
            .nonNulls
            .join(', ') ??
        '';

    _addition = '$name($argumentList)';

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
      ChangeBuilder builder, ExpressionFunctionBody body) async {
    var expression = body.expression;
    var semicolon = body.semicolon;
    var prefix = utils.getLinePrefix(expression.offset);
    var prefixWithLine = eol + prefix + utils.oneIndent;

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.startStart(body.functionDefinition, expression),
          '{${prefixWithLine}super.$_addition;${prefixWithLine}return ');

      builder.addSimpleReplacement(
          range.endEnd(expression, semicolon ?? expression), ';$eol$prefix}');
    });
  }
}
