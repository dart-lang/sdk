// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class AddCallSuper extends CorrectionProducer {
  var _addition = '';

  @override
  // Adding as the first statement is not predictably the correct action.
  bool get canBeAppliedInBulk => false;

  @override
  // Adding as the first statement is not predictably the correct action.
  bool get canBeAppliedToFile => false;

  @override
  List<Object> get fixArguments => [_addition];

  @override
  FixKind get fixKind => DartFixKind.ADD_CALL_SUPER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier) return;
    var methodDeclaration = node.thisOrAncestorOfType<MethodDeclaration>();
    if (methodDeclaration == null) return;
    var classElement = methodDeclaration
        .thisOrAncestorOfType<ClassDeclaration>()
        ?.declaredElement;
    if (classElement == null) return;

    var name = Name(classElement.library.source.uri, node.name);
    var overridden = InheritanceManager3().getInherited2(classElement, name);
    if (overridden == null) return;
    var overriddenParameters = overridden.parameters.map((p) => p.name);

    var body = methodDeclaration.body;
    var parameters = methodDeclaration.parameters?.parameters;
    var argumentList = parameters
            ?.map((p) {
              var name = p.identifier?.name;
              if (overriddenParameters.contains(name)) {
                return p.isNamed ? '$name: $name' : name;
              }
              return null;
            })
            .whereNotNull()
            .join(', ') ??
        '';

    _addition = '${node.name}($argumentList)';

    if (body is BlockFunctionBody) {
      await _block(builder, body);
    } else if (body is ExpressionFunctionBody) {
      await _expression(builder, body);
    }
  }

  Future<void> _block(ChangeBuilder builder, BlockFunctionBody body) async {
    var location = utils.prepareNewStatementLocation(body.block, true);

    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(location.offset, (builder) {
        builder.write(location.prefix);
        builder.write('super.$_addition;');
        builder.write(location.suffix);
      });
    });
  }

  Future<void> _expression(
      ChangeBuilder builder, ExpressionFunctionBody body) async {
    var expression = body.expression;
    var semicolon = body.semicolon;
    var prefix = utils.getLinePrefix(expression.offset);
    var prefixWithLine = eol + prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.startStart(body.functionDefinition, expression),
          '{${prefixWithLine}super.$_addition;${prefixWithLine}return ');

      builder.addSimpleReplacement(
          range.endEnd(expression, semicolon ?? expression), ';$eol$prefix}');
    });
  }
}
