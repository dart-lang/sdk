// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:collection/collection.dart';

class RemoveConstructor extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // Not predictably the correct action.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_CONSTRUCTOR;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var container = _findContainer();
    if (container == null) {
      return;
    }

    var constructor = _findConstructor();
    if (constructor == null) {
      return;
    }

    var previous = container.members.lastWhereOrNull(
      (e) => e.end < constructor.offset,
    );

    await builder.addDartFileEdit(file, (builder) {
      var constructorRange = range.endEnd(
        previous?.endToken ?? container.leftBracket,
        constructor.endToken,
      );
      builder.addDeletion(constructorRange);
    });
  }

  ConstructorDeclaration? _findConstructor() {
    var errorOffset = this.errorOffset;
    if (errorOffset == null) {
      return null;
    }

    for (var constructor in invalidNodes) {
      if (constructor is ConstructorDeclaration) {
        if (range.node(constructor).contains(errorOffset)) {
          return constructor;
        }
      }
    }

    return null;
  }

  _Container? _findContainer() {
    switch (node) {
      case ExtensionDeclaration extension:
        return _Container(
          leftBracket: extension.leftBracket,
          members: extension.members,
        );
      case MixinDeclaration mixin:
        return _Container(
          leftBracket: mixin.leftBracket,
          members: mixin.members,
        );
      default:
        return null;
    }
  }
}

class _Container {
  final Token leftBracket;
  final List<ClassMember> members;

  _Container({
    required this.leftBracket,
    required this.members,
  });
}
