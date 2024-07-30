// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddEnumConstant extends ResolvedCorrectionProducer {
  /// The name of the constant to be created.
  String _constantName = '';

  AddEnumConstant({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_constantName];

  @override
  FixKind get fixKind => DartFixKind.ADD_ENUM_CONSTANT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier) return;
    var parent = node.parent;
    if (parent is! PrefixedIdentifier) return;

    _constantName = node.name;
    var target = parent.prefix;

    var targetElement = target.staticElement;
    if (targetElement == null) return;
    if (targetElement.library?.isInSdk == true) return;

    var targetDeclarationResult =
        await sessionHelper.getElementDeclaration(targetElement);
    if (targetDeclarationResult == null) return;
    var targetNode = targetDeclarationResult.node;
    if (targetNode is! EnumDeclaration) return;

    var targetUnit = targetDeclarationResult.resolvedUnit;
    if (targetUnit == null) return;

    var targetSource = targetElement.source;
    var targetFile = targetSource?.fullName;
    if (targetFile == null) return;

    var constructors = targetNode.members
        .whereType<ConstructorDeclaration>()
        .where((con) => con.factoryKeyword == null);

    if (constructors.any((con) => con.parameters.parameters.isNotEmpty)) {
      return;
    }

    var length = constructors.length;
    if (length > 1) return;

    var constructorName = length == 1 ? constructors.first.name?.lexeme : null;
    var addition = constructorName != null ? '.$constructorName()' : '';

    var lastConstant = targetNode.constants.lastOrNull;

    await builder.addDartFileEdit(targetFile, (builder) {
      if (lastConstant != null) {
        builder.addInsertion(lastConstant.end, (builder) {
          builder.write(', ');
          builder.write(_constantName);
          builder.write(addition);
        });
      } else {
        builder.addInsertion(targetNode.rightBracket.offset, (builder) {
          builder.write(_constantName);
          builder.write(addition);
        });
      }
    });
  }
}
