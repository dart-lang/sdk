// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

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
  FixKind get fixKind => DartFixKind.addEnumConstant;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! SimpleIdentifier) return;
    _constantName = node.name;

    Element? targetElement;
    var parent = node.parent;
    if (parent is PrefixedIdentifier) {
      targetElement = parent.prefix.element;
    } else if (parent is DotShorthandPropertyAccess) {
      targetElement = computeDotShorthandContextTypeElement(
        parent,
        unitResult.libraryElement,
      );
    }

    if (targetElement is! EnumElement) return;
    if (targetElement.library.isInSdk) return;

    var targetFragment = targetElement.firstFragment;
    var targetDeclarationResult = await sessionHelper.getFragmentDeclaration(
      targetFragment,
    );
    var targetNode = targetDeclarationResult?.node;
    if (targetNode is! EnumDeclaration) return;

    var constructors = targetElement.constructors
        .where((c) => !c.isFactory)
        .toList();
    if (constructors.any((c) => c.formalParameters.isNotEmpty)) return;

    String? constructorName;
    if (constructors.isNotEmpty) {
      if (constructors.length > 1) return;
      if (constructors.first.name != 'new') {
        constructorName = constructors.first.name;
      }
    }

    EnumConstantDeclaration? lastConstant;
    Token? rightBracket;
    Token? semicolon;
    switch (targetNode.body) {
      case BlockEnumBody body:
        lastConstant = body.constants.lastOrNull;
        rightBracket = body.rightBracket;
      case EmptyEnumBody body:
        semicolon = body.semicolon;
    }

    var targetFile = targetFragment.libraryFragment.source.fullName;

    await builder.addDartFileEdit(targetFile, (builder) {
      if (lastConstant != null) {
        builder.addInsertion(lastConstant.end, (builder) {
          builder.write(', ');
          builder.write(_constantName);
          if (constructorName != null) builder.write('.$constructorName()');
        });
      } else if (rightBracket != null) {
        // If has a block body.
        builder.addInsertion(rightBracket.offset, (builder) {
          builder.write(_constantName);
          if (constructorName != null) builder.write('.$constructorName()');
        });
      } else if (semicolon != null) {
        builder.addReplacement(range.token(semicolon), (builder) {
          builder.write(' { ');
          builder.write(_constantName);
          if (constructorName != null) builder.write('.$constructorName()');
          builder.write(' }');
        });
      }
    });
  }
}
