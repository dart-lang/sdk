// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/base/source_range.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveTypeName extends ResolvedCorrectionProducer {
  RemoveTypeName({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeTypeName;

  @override
  FixKind? get multiFixKind => DartFixKind.removeTypeNameMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = coveringNode;
    if (node is! SimpleIdentifier) return;
    node = node.parent;
    if (node is ConstructorDeclaration) {
      var typeName = node.typeName;
      if (typeName == null) return;
      var name = node.name;
      var newOrFactoryKeyword = node.newKeyword ?? node.factoryKeyword;
      var replacementBeginToken = typeName.beginToken;
      Token replacementEndToken;
      if (name == null) {
        replacementEndToken = typeName.endToken;
      } else if (name.lexeme == 'new') {
        replacementEndToken = name;
      } else {
        var period = node.period;
        if (period == null) {
          // Name but no `.`. This can only happen in the event of a syntax
          // error, so for safety, don't produce any correction.
          return;
        }
        replacementEndToken = period;
      }
      SourceRange replacementRange;
      String replacement;
      if (newOrFactoryKeyword != null) {
        if (name == null &&
            newOrFactoryKeyword.end + 1 == replacementBeginToken.offset) {
          // Changing e.g., `factory ClassName(...)` to `factory(...)`, so
          // delete the space after `factory`.
          replacementRange = range.endEnd(
            newOrFactoryKeyword,
            replacementEndToken,
          );
        } else {
          replacementRange = range.startEnd(
            replacementBeginToken,
            replacementEndToken,
          );
        }
        replacement = '';
      } else {
        replacementRange = range.startEnd(
          replacementBeginToken,
          replacementEndToken,
        );
        if (replacementEndToken.isIdentifier) {
          // The text we are replacing ends in an identifier, so if a space is
          // needed after `new`, it is already present.
          replacement = 'new';
        } else {
          // The text we are replacing is a typeName followed by `.`. Typically
          // this is followed immediately by the constructor name, so insert a
          // space after `new`.
          replacement = 'new ';
        }
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(replacementRange, replacement);
      });
    }
  }
}
